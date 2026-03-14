import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_pagination_decoder.dart';

const TenantAdminPaginationDecoder _tenantAdminPaginationDecoder =
    TenantAdminPaginationDecoder();

int? tenantAdminReadPageValue(Object? source, String key) {
  return _tenantAdminPaginationDecoder.readPageValue(source, key);
}

bool tenantAdminResolveHasMore({
  required Object? rawResponse,
  required int requestedPage,
}) {
  return _tenantAdminPaginationDecoder.resolveHasMore(
    rawResponse: rawResponse,
    requestedPage: requestedPage,
  );
}
