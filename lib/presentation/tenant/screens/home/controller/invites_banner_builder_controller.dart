import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class InvitesBannerBuilderController {
  final _invitesRepository = GetIt.I.get<InvitesRepositoryContract>();

  StreamValue<List<InviteModel>> get pendingInvitesStreamValue =>
      _invitesRepository.pendingInvitesStreamValue;

  bool get hasPendingInvites => _invitesRepository.hasPendingInvites;
}