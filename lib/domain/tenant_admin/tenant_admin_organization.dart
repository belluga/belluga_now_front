export 'value_objects/tenant_admin_organization_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminOrganization {
  TenantAdminOrganization({
    required this.idValue,
    required this.nameValue,
    required this.slugValue,
    required this.descriptionValue,
  });

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue nameValue;
  final TenantAdminOptionalTextValue slugValue;
  final TenantAdminOptionalTextValue descriptionValue;

  String get id => idValue.value;
  String get name => nameValue.value;
  String? get slug => slugValue.nullableValue;
  String? get description => descriptionValue.nullableValue;
}
