import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_publication.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminAccountPublication tenantAdminAccountPublicationFromRaw({
  required Object? status,
}) {
  final normalizedStatus = status?.toString().trim();
  return TenantAdminAccountPublication(
    statusValue: tenantAdminRequiredText(
      (normalizedStatus == null || normalizedStatus.isEmpty)
          ? 'draft'
          : normalizedStatus,
    ),
  );
}
