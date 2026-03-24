import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminAccount {
  TenantAdminAccount({
    required Object id,
    required Object name,
    required Object slug,
    required this.document,
    required this.ownershipState,
    Object? organizationId,
    Object? avatarUrl,
  })  : idValue = tenantAdminRequiredText(id),
        nameValue = tenantAdminRequiredText(name),
        slugValue = tenantAdminRequiredText(slug),
        organizationIdValue = tenantAdminOptionalText(organizationId),
        avatarUrlValue = tenantAdminOptionalUrl(avatarUrl);

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue nameValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminDocument document;
  final TenantAdminOwnershipState ownershipState;
  final TenantAdminOptionalTextValue organizationIdValue;
  final TenantAdminOptionalUrlValue avatarUrlValue;

  String get id => idValue.value;
  String get name => nameValue.value;
  String get slug => slugValue.value;
  String? get organizationId => organizationIdValue.nullableValue;
  String? get avatarUrl => avatarUrlValue.nullableValue;
}
