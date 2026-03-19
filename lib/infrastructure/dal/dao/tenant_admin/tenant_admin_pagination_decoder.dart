class TenantAdminPaginationDecoder {
  const TenantAdminPaginationDecoder();

  int? readPageValue(Object? source, String key) {
    if (source is! Map) {
      return null;
    }
    final value = source[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Object? extractMetaNode(Object? rawResponse) {
    if (rawResponse is! Map) {
      return null;
    }
    return rawResponse['meta'];
  }

  bool resolveHasMore({
    required Object? rawResponse,
    required int requestedPage,
  }) {
    if (rawResponse is! Map) {
      return false;
    }
    final currentPage = readPageValue(rawResponse, 'current_page') ??
        readPageValue(rawResponse['meta'], 'current_page') ??
        requestedPage;
    final lastPage = readPageValue(rawResponse, 'last_page') ??
        readPageValue(rawResponse['meta'], 'last_page') ??
        currentPage;
    return currentPage < lastPage;
  }
}
