import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminOrganization tenantAdminOrganizationFromRaw({
  required Object? id,
  required Object? name,
  Object? slug,
  Object? description,
}) {
  return TenantAdminOrganization(
    idValue: tenantAdminRequiredText(id),
    nameValue: tenantAdminRequiredText(name),
    slugValue: tenantAdminOptionalText(slug),
    descriptionValue: tenantAdminOptionalText(description),
  );
}
