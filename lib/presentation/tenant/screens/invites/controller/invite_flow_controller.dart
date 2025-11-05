import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:card_stack_swiper/card_stack_swiper.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteFlowController {
  InviteFlowController();

  final _repository = GetIt.I.get<InvitesRepositoryContract>();

  final swiperController = CardStackSwiperController();

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

  final confirmingPresenceStreamValue =
      StreamValue<bool>(defaultValue: false);

  Future<void> init() async {
    await fetchPendingInvites();
  }

  Future<void> fetchPendingInvites() async {
    final _invites = await _repository.fetchInvites();
    pendingInvitesStreamValue.addValue(_invites);
  }

  void removeInvite() {
    final List<InviteModel> _pendingInvites = pendingInvitesStreamValue.value;

    if (_pendingInvites.isEmpty) {
      return;
    }

    _pendingInvites.removeAt(0);

    pendingInvitesStreamValue.addValue(_pendingInvites);
  }

  void addInvite(InviteModel invite) {
    final _pendingInvites = pendingInvitesStreamValue.value;
    _pendingInvites.add(invite);

    pendingInvitesStreamValue.addValue(_pendingInvites);
  }

  InviteModel? respondToInvite(InviteDecision decision) {
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

    confirmingPresenceStreamValue.addValue(false);
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

  Future<void> dispose() async {
    decisionsStreamValue.dispose();
    swiperController.dispose();
    confirmingPresenceStreamValue.dispose();
  }
}
