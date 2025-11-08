import 'dart:async';

import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteFlowScreenController with Disposable {
  InviteFlowScreenController({
    InvitesRepositoryContract? repository,
    CardStackSwiperController? cardStackSwiperController,
  })  : _repository = repository ?? GetIt.I.get<InvitesRepositoryContract>(),
        swiperController =
            cardStackSwiperController ?? CardStackSwiperController();

  final InvitesRepositoryContract _repository;

  final CardStackSwiperController swiperController;

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

  Future<void> init() async {
    await fetchPendingInvites();
  }

  Future<void> fetchPendingInvites() async {
    final _invites = await _repository.fetchInvites();
    pendingInvitesStreamValue.addValue(_invites);
    _ensureTopIndexBounds(_invites.length);
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

  Future<InviteModel?> applyDecision(InviteDecision decision) async {
    final invite = await _finalizeDecision(decision);
    if (decision != InviteDecision.accepted) {
      resetConfirmPresence();
    }
    return invite;
  }

  Future<InviteModel?> _finalizeDecision(InviteDecision decision) async {
    final _pendingInvites = pendingInvitesStreamValue.value;

    final current = _pendingInvites.isEmpty ? null : _pendingInvites.first;
    if (current == null) {
      return null;
    }

    _decisions[current.id] = decision;
    removeInvite();
    decisionsStreamValue.addValue(Map.unmodifiable(_decisions));

    if (decision == InviteDecision.accepted) {
      return current;
    }

    return null;
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
