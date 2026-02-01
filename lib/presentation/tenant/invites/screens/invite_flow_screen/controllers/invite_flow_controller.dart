import 'dart:async';
import 'dart:collection';

import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_inviter_type.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
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
  final _RetryQueue _inviteQueue = _RetryQueue();

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
  Future<EventTrackerTimedEventHandle?>? _activeInviteTimedEventFuture;
  String? _activeInviteId;
  StreamSubscription<List<InviteModel>>? _pendingInvitesSubscription;

  Future<void> init({String? prioritizeInviteId}) async {
    _ensureInviteTrackingSubscription();
    await fetchPendingInvites();
    if (prioritizeInviteId != null && prioritizeInviteId.isNotEmpty) {
      _prioritizeInvite(prioritizeInviteId);
    }
  }

  Future<void> fetchPendingInvites() async {
    final _invites = await _repository.fetchInvites();
    pendingInvitesStreamValue.addValue(_invites);
    _ensureTopIndexBounds(_invites.length);
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

    _finishActiveInviteTimedEvent(expectedInviteId: current.id);
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

  void _ensureInviteTrackingSubscription() {
    if (_pendingInvitesSubscription != null) {
      return;
    }
    _pendingInvitesSubscription =
        pendingInvitesStreamValue.stream.listen(_handleInviteStreamUpdate);
    _handleInviteStreamUpdate(pendingInvitesStreamValue.value);
  }

  void _handleInviteStreamUpdate(List<InviteModel> invites) {
    if (invites.isEmpty) {
      _finishActiveInviteTimedEvent();
      return;
    }
    unawaited(_trackInviteOpened(invites));
  }

  Future<void> _trackInviteOpened(List<InviteModel> invites) async {
    if (invites.isEmpty) return;
    final current = invites.first;
    if (_activeInviteId != null && _activeInviteId != current.id) {
      _finishActiveInviteTimedEvent();
    }
    if (_openedInviteIds.add(current.id)) {
      _activeInviteTimedEventFuture = _telemetryRepository.startTimedEvent(
        EventTrackerEvents.inviteOpened,
        eventName: 'invite_opened',
        properties: _buildInviteTelemetryProperties(current),
      );
      _activeInviteId = current.id;
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
  FutureOr<void> onDispose() {
    _pendingInvitesSubscription?.cancel();
    _pendingInvitesSubscription = null;
    _finishActiveInviteTimedEvent();
    decisionsStreamValue.dispose();
    swiperController.dispose();
    confirmingPresenceStreamValue.dispose();
    topCardIndexStreamValue.dispose();
  }

  void _finishActiveInviteTimedEvent({
    String? expectedInviteId,
  }) {
    final handleFuture = _activeInviteTimedEventFuture;
    if (handleFuture == null) {
      return;
    }
    if (expectedInviteId != null && _activeInviteId != expectedInviteId) {
      return;
    }
    _activeInviteTimedEventFuture = null;
    _activeInviteId = null;
    unawaited(handleFuture.then<void>((handle) async {
      if (handle != null) {
        await _telemetryRepository.finishTimedEvent(handle);
      }
    }));
  }
}

class _RetryQueue {
  _RetryQueue({
    List<Duration>? retryDelays,
  }) : _retryDelays = retryDelays ??
            const [
              Duration.zero,
              Duration(seconds: 2),
              Duration(seconds: 4),
              Duration(seconds: 4),
            ];

  final List<Duration> _retryDelays;
  final Queue<_RetryJob> _jobs = Queue<_RetryJob>();
  bool _processing = false;

  Future<bool> enqueue(Future<void> Function() task) {
    final completer = Completer<bool>();
    _jobs.add(_RetryJob(task: task, completer: completer));
    _process();
    return completer.future;
  }

  Future<void> _process() async {
    if (_processing) return;
    _processing = true;

    while (_jobs.isNotEmpty) {
      final job = _jobs.removeFirst();
      var success = false;

      for (final delay in _retryDelays) {
        if (delay > Duration.zero) {
          await Future<void>.delayed(delay);
        }
        try {
          await job.task();
          success = true;
          break;
        } catch (_) {
          success = false;
        }
      }

      if (!job.completer.isCompleted) {
        job.completer.complete(success);
      }
    }

    _processing = false;
  }
}

class _RetryJob {
  _RetryJob({
    required this.task,
    required this.completer,
  });

  final Future<void> Function() task;
  final Completer<bool> completer;
}

class InviteDecisionResult {
  const InviteDecisionResult({
    required this.invite,
    required this.queued,
  });

  final InviteModel? invite;
  final bool queued;
}
