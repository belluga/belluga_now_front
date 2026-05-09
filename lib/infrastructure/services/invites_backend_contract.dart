import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_realtime_delta_dto.dart';

abstract class InvitesBackendContract {
  Future<Map<String, dynamic>> fetchInvites({
    required int page,
    required int pageSize,
  });

  Stream<InviteRealtimeDeltaDto> watchInvitesStream({
    String? lastEventId,
  });

  Future<Map<String, dynamic>> fetchSettings();

  Future<Map<String, dynamic>> acceptInvite(String inviteId);

  Future<Map<String, dynamic>> declineInvite(String inviteId);

  Future<Map<String, dynamic>> sendInvites(InviteSendRequest request);

  Future<Map<String, dynamic>> createShareCode(
    InviteShareCodeCreateRequest request,
  );

  Future<Map<String, dynamic>> fetchShareCodePreview(String code);

  Future<Map<String, dynamic>> acceptShareCode(String code);

  Future<Map<String, dynamic>> materializeShareCode(String code);

  Future<Map<String, dynamic>> importContacts(
    InviteContactImportRequest request,
  );

  Future<Map<String, dynamic>> fetchInviteableContacts();

  Future<Map<String, dynamic>> fetchContactGroups();

  Future<Map<String, dynamic>> createContactGroup({
    required String name,
    required List<String> recipientAccountProfileIds,
  });

  Future<Map<String, dynamic>> updateContactGroup({
    required String groupId,
    String? name,
    List<String>? recipientAccountProfileIds,
  });

  Future<Map<String, dynamic>> deleteContactGroup(String groupId);
}
