int? tenantAdminReadPageValue(dynamic source, String key) {
  if (source is! Map) {
    return null;
  }
  final value = source[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool tenantAdminResolveHasMore({
  required dynamic rawResponse,
  required int requestedPage,
}) {
  if (rawResponse is! Map<String, dynamic>) {
    return false;
  }
  final currentPage = tenantAdminReadPageValue(rawResponse, 'current_page') ??
      tenantAdminReadPageValue(rawResponse['meta'], 'current_page') ??
      requestedPage;
  final lastPage = tenantAdminReadPageValue(rawResponse, 'last_page') ??
      tenantAdminReadPageValue(rawResponse['meta'], 'last_page') ??
      currentPage;
  return currentPage < lastPage;
}
