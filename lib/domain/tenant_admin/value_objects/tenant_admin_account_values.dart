import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminAccount tenantAdminAccountFromRaw({
  required Object? id,
  required Object? name,
  required Object? slug,
  required TenantAdminDocument document,
  required TenantAdminOwnershipState ownershipState,
  Object? organizationId,
  Object? avatarUrl,
}) {
  return TenantAdminAccount(
    idValue: tenantAdminRequiredText(id),
    nameValue: tenantAdminRequiredText(name),
    slugValue: tenantAdminRequiredText(slug),
    document: document,
    ownershipState: ownershipState,
    organizationIdValue: tenantAdminOptionalText(organizationId),
    avatarUrlValue: tenantAdminOptionalUrl(avatarUrl),
  );
}
