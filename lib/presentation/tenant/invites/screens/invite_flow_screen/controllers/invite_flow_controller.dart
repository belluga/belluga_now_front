import 'dart:async';

import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_queue.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteFlowScreenController with Disposable {
  InviteFlowScreenController({
    InvitesRepositoryContract? repository,
    UserEventsRepositoryContract? userEventsRepository,
    TelemetryRepositoryContract? telemetryRepository,
    CardStackSwiperController? cardStackSwiperController,
  })  : _repository = repository ?? GetIt.I.get<InvitesRepositoryContract>(),
        _userEventsRepository =
            userEventsRepository ?? GetIt.I.get<UserEventsRepositoryContract>(),
        _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>(),
        swiperController =
            cardStackSwiperController ?? CardStackSwiperController();

  final InvitesRepositoryContract _repository;
  final UserEventsRepositoryContract _userEventsRepository;
  final TelemetryRepositoryContract _telemetryRepository;

  final CardStackSwiperController swiperController;
  final TelemetryQueue _inviteQueue = TelemetryQueue();

  InviteModel? get currentInvite => pendingInvitesStreamValue.value.isNotEmpty
      ? pendingInvitesStreamValue.value.first
      : null;

  final decisionsStreamValue =
      StreamValue<Map<String, InviteDecision>>(defaultValue: const {});

  StreamValue<List<InviteModel>> get pendingInvitesStreamValue =>
      _repository.pendingInvitesStreamValue;

  final Map<String, InviteDecision> _decisions = <String, InviteDecision>{};

  bool get hasPendingInvites => _repository.hasPendingInvites;
  Map<String, InviteDecision> get decisions => Map.unmodifiable(_decisions);

  final confirmingPresenceStreamValue = StreamValue<bool>(defaultValue: false);
  final topCardIndexStreamValue = StreamValue<int>(defaultValue: 0);
  final Set<String> _openedInviteIds = <String>{};

  Future<void> init({String? prioritizeInviteId}) async {
    await fetchPendingInvites();
    if (prioritizeInviteId != null && prioritizeInviteId.isNotEmpty) {
      _prioritizeInvite(prioritizeInviteId);
    }
  }

  Future<void> fetchPendingInvites() async {
    final _invites = await _repository.fetchInvites();
    pendingInvitesStreamValue.addValue(_invites);
    _ensureTopIndexBounds(_invites.length);
    await _trackInviteOpened(_invites);
  }

  void _prioritizeInvite(String inviteId) {
    final invites = List<InviteModel>.from(pendingInvitesStreamValue.value);
    final index = invites.indexWhere((invite) => invite.id == inviteId);
    if (index <= 0) {
      return;
    }
    final invite = invites.removeAt(index);
    invites.insert(0, invite);
    pendingInvitesStreamValue.addValue(invites);
    _ensureTopIndexBounds(invites.length);
    unawaited(_trackInviteOpened(invites));
  }

  void removeInvite() {
    final List<InviteModel> _pendingInvites = pendingInvitesStreamValue.value;

    if (_pendingInvites.isEmpty) {
      return;
    }

    _pendingInvites.removeAt(0);

    pendingInvitesStreamValue.addValue(_pendingInvites);
    _ensureTopIndexBounds(_pendingInvites.length);
  }

  void addInvite(InviteModel invite) {
    final _pendingInvites = pendingInvitesStreamValue.value;
    _pendingInvites.add(invite);

    pendingInvitesStreamValue.addValue(_pendingInvites);
    _ensureTopIndexBounds(_pendingInvites.length);
  }

  Future<InviteDecisionResult?> applyDecision(InviteDecision decision) async {
    final result = await _finalizeDecision(decision);
    if (decision != InviteDecision.accepted) {
      resetConfirmPresence();
    }
    return result;
  }

  Future<InviteDecisionResult?> _finalizeDecision(
    InviteDecision decision,
  ) async {
    final _pendingInvites = pendingInvitesStreamValue.value;

    final current = _pendingInvites.isEmpty ? null : _pendingInvites.first;
    if (current == null) {
      return null;
    }

    _decisions[current.id] = decision;
    decisionsStreamValue.addValue(Map.unmodifiable(_decisions));

    if (decision == InviteDecision.accepted) {
      var queued = false;
      try {
        await _userEventsRepository.confirmEventAttendance(current.eventId);
      } catch (_) {
        queued = true;
        await _inviteQueue.enqueue(
          () => _userEventsRepository.confirmEventAttendance(current.eventId),
        );
      }
      return InviteDecisionResult(invite: current, queued: queued);
    }

    // Decline: remove immediately
    removeInvite();
    return const InviteDecisionResult(invite: null, queued: false);
  }

  void rewindInvite(InviteModel invite) {
    addInvite(invite);

    _decisions.remove(invite.id);
    decisionsStreamValue.addValue(Map.unmodifiable(_decisions));
  }

  bool beginConfirmPresence() {
    if (confirmingPresenceStreamValue.value) {
      return false;
    }

    if (!hasPendingInvites) {
      return false;
    }

    confirmingPresenceStreamValue.addValue(true);
    return true;
  }

  void resetConfirmPresence() {
    confirmingPresenceStreamValue.addValue(false);
  }

  void updateTopCardIndex({
    required int previousIndex,
    required int? currentIndex,
    required int invitesLength,
  }) {
    if (invitesLength == 0) {
      topCardIndexStreamValue.addValue(0);
      return;
    }

    final nextIndex =
        (currentIndex ?? previousIndex).clamp(0, invitesLength - 1);
    if (nextIndex != topCardIndexStreamValue.value) {
      topCardIndexStreamValue.addValue(nextIndex);
    }
  }

  void _ensureTopIndexBounds(int invitesLength) {
    if (invitesLength <= 0) {
      if (topCardIndexStreamValue.value != 0) {
        topCardIndexStreamValue.addValue(0);
      }
      return;
    }

    final current = topCardIndexStreamValue.value;
    final clamped = current.clamp(0, invitesLength - 1);
    if (clamped != current) {
      topCardIndexStreamValue.addValue(clamped);
    }
  }

  Future<void> _trackInviteOpened(List<InviteModel> invites) async {
    if (invites.isEmpty) return;
    final current = invites.first;
    if (_openedInviteIds.add(current.id)) {
      await _telemetryRepository.logEvent(
        EventTrackerEvents.inviteOpened,
        eventName: 'invite_opened',
        properties: _buildInviteTelemetryProperties(current),
      );
    }
  }

  Map<String, dynamic> _buildInviteTelemetryProperties(InviteModel invite) {
    final properties = <String, dynamic>{
      'event_id': invite.eventId,
      'source': 'invite_flow',
    };

    final inviterPrincipal = invite.inviterPrincipal;
    if (inviterPrincipal != null) {
      properties['inviter_kind'] = inviterPrincipal.type.name;
      properties['inviter_id'] = inviterPrincipal.id;
      if (inviterPrincipal.type == InviteInviterType.partner) {
        properties['partner_id'] = inviterPrincipal.id;
      }
    }

    return properties;
  }

  void syncTopCardIndex(int invitesLength) {
    _ensureTopIndexBounds(invitesLength);
  }

  @override
  FutureOr<void> onDispose() async {
    decisionsStreamValue.dispose();
    swiperController.dispose();
    confirmingPresenceStreamValue.dispose();
    topCardIndexStreamValue.dispose();
  }
}

class InviteDecisionResult {
  const InviteDecisionResult({
    required this.invite,
    required this.queued,
  });

  final InviteModel? invite;
  final bool queued;
}
