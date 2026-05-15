import 'dart:async';

import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InvitesBannerBuilderController {
  InvitesBannerBuilderController({
    InvitesRepositoryContract? invitesRepository,
  }) : _invitesRepository =
            invitesRepository ?? GetIt.I.get<InvitesRepositoryContract>();

  final InvitesRepositoryContract _invitesRepository;
  final isPendingInvitesDisplayReadyStreamValue =
      StreamValue<bool>(defaultValue: false);
  StreamSubscription<List<InviteModel>>? _pendingInvitesSubscription;
  List<String> _initialInviteIds = const <String>[];

  void init() {
    isPendingInvitesDisplayReadyStreamValue.addValue(false);
    _initialInviteIds = _inviteIds(_invitesRepository.pendingInvitesStreamValue.value);
    _pendingInvitesSubscription?.cancel();
    _pendingInvitesSubscription =
        _invitesRepository.pendingInvitesStreamValue.stream.listen(
      (invites) {
        if (isPendingInvitesDisplayReadyStreamValue.value) {
          return;
        }
        if (_didInviteStateChangeFromInitial(invites)) {
          isPendingInvitesDisplayReadyStreamValue.addValue(true);
        }
      },
    );
    unawaited(_revalidatePendingInvitesForDisplay());
  }

  StreamValue<List<InviteModel>> get pendingInvitesStreamValue =>
      _invitesRepository.pendingInvitesStreamValue;

  bool get hasPendingInvites =>
      isPendingInvitesDisplayReadyStreamValue.value &&
      pendingInvitesStreamValue.value.isNotEmpty;

  Future<void> _revalidatePendingInvitesForDisplay() async {
    try {
      await _invitesRepository.refreshPendingInvites();
      isPendingInvitesDisplayReadyStreamValue.addValue(true);
    } catch (_) {
      isPendingInvitesDisplayReadyStreamValue.addValue(false);
    }
  }

  bool _didInviteStateChangeFromInitial(List<InviteModel> invites) {
    final nextIds = _inviteIds(invites);
    if (nextIds.length != _initialInviteIds.length) {
      return true;
    }
    for (var index = 0; index < nextIds.length; index++) {
      if (nextIds[index] != _initialInviteIds[index]) {
        return true;
      }
    }
    return false;
  }

  List<String> _inviteIds(List<InviteModel> invites) {
    return invites.map((invite) => invite.id).toList(growable: false);
  }

  void onDispose() {
    _pendingInvitesSubscription?.cancel();
    _pendingInvitesSubscription = null;
    isPendingInvitesDisplayReadyStreamValue.dispose();
  }
}
