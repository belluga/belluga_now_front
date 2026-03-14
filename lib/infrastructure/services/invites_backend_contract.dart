abstract class InvitesBackendContract {
  Future<Map<String, dynamic>> fetchInvites({
    required int page,
    required int pageSize,
  });

  Future<Map<String, dynamic>> fetchSettings();

  Future<Map<String, dynamic>> acceptInvite(String inviteId);

  Future<Map<String, dynamic>> declineInvite(String inviteId);

  Future<Map<String, dynamic>> sendInvites(Map<String, dynamic> payload);

  Future<Map<String, dynamic>> createShareCode(Map<String, dynamic> payload);

  Future<Map<String, dynamic>> acceptShareCode(String code);

  Future<Map<String, dynamic>> importContacts(Map<String, dynamic> payload);
}
