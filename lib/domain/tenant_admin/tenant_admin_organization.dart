import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminOrganization {
  TenantAdminOrganization({
    required Object id,
    required Object name,
    Object? slug,
    Object? description,
  })  : idValue = tenantAdminRequiredText(id),
        nameValue = tenantAdminRequiredText(name),
        slugValue = tenantAdminOptionalText(slug),
        descriptionValue = tenantAdminOptionalText(description);

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue nameValue;
  final TenantAdminOptionalTextValue slugValue;
  final TenantAdminOptionalTextValue descriptionValue;

  String get id => idValue.value;
  String get name => nameValue.value;
  String? get slug => slugValue.nullableValue;
  String? get description => descriptionValue.nullableValue;
}
