export 'value_objects/tenant_admin_taxonomy_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminTaxonomy {
  TenantAdminTaxonomy({
    required this.idValue,
    required this.slugValue,
    required this.nameValue,
    required this.appliesToValue,
    required this.iconValue,
    required this.colorValue,
  });

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminRequiredTextValue nameValue;
  final TenantAdminTrimmedStringListValue appliesToValue;
  final TenantAdminOptionalTextValue iconValue;
  final TenantAdminOptionalTextValue colorValue;

  String get id => idValue.value;
  String get slug => slugValue.value;
  String get name => nameValue.value;
  TenantAdminTrimmedStringListValue get appliesTo => appliesToValue;
  String? get icon => iconValue.nullableValue;
  String? get color => colorValue.nullableValue;
}
