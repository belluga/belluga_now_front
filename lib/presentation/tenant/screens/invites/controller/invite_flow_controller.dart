import 'dart:collection';

import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_friend_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InviteFlowController implements Disposable {
  InviteFlowController({
    InvitesRepositoryContract? repository,
  }) : _repository = repository ?? GetIt.I.get<InvitesRepositoryContract>();

  final InvitesRepositoryContract _repository;

  final StreamValue<InviteModel?> currentInviteStreamValue =
      StreamValue<InviteModel?>();
  final StreamValue<int> remainingInvitesStreamValue =
      StreamValue<int>(defaultValue: 0);
  final StreamValue<Map<String, InviteDecision>> decisionsStreamValue =
      StreamValue<Map<String, InviteDecision>>(defaultValue: const {});

  final ListQueue<InviteModel> _pendingInvites = ListQueue<InviteModel>();
  final Map<String, InviteDecision> _decisions = <String, InviteDecision>{};
  List<InviteFriendModel> _friendSuggestions = const <InviteFriendModel>[];

  bool get hasPendingInvites => _pendingInvites.isNotEmpty;
  List<InviteFriendModel> get friendSuggestions =>
      List.unmodifiable(_friendSuggestions);
  Map<String, InviteDecision> get decisions => Map.unmodifiable(_decisions);

  Future<void> init() async {
    final invites = await _repository.fetchInvites();
    final friends = await _repository.fetchFriendSuggestions();

    _pendingInvites
      ..clear()
      ..addAll(invites);
    _friendSuggestions = friends;

    _emitState();
  }

  InviteModel? respondToInvite(InviteDecision decision) {
    final current = _pendingInvites.isEmpty ? null : _pendingInvites.first;
    if (current == null) {
      return null;
    }

    _decisions[current.id] = decision;
    _pendingInvites.removeFirst();
    decisionsStreamValue.addValue(Map.unmodifiable(_decisions));
    _emitState();

    if (decision == InviteDecision.accepted) {
      return current;
    }

    return null;
  }

  void rewindInvite(InviteModel invite) {
    _pendingInvites.addFirst(invite);
    _decisions.remove(invite.id);
    _emitState();
    decisionsStreamValue.addValue(Map.unmodifiable(_decisions));
  }

  void _emitState() {
    final nextInvite = _pendingInvites.isEmpty ? null : _pendingInvites.first;
    currentInviteStreamValue.addValue(nextInvite);
    remainingInvitesStreamValue.addValue(_pendingInvites.length);
  }

  @override
  void onDispose() {
    currentInviteStreamValue.dispose();
    remainingInvitesStreamValue.dispose();
    decisionsStreamValue.dispose();
  }
}
