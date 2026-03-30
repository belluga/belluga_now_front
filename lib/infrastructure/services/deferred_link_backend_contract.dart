abstract class DeferredLinkBackendContract {
  Future<Map<String, dynamic>> resolveDeferredLink({
    required String platform,
    String? installReferrer,
    String? storeChannel,
  });
}
