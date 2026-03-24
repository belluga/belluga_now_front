import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminTaxonomy {
  TenantAdminTaxonomy({
    required Object id,
    required Object slug,
    required Object name,
    required Object appliesTo,
    Object? icon,
    Object? color,
  })  : idValue = tenantAdminRequiredText(id),
        slugValue = tenantAdminRequiredText(slug),
        nameValue = tenantAdminRequiredText(name),
        appliesToValue = tenantAdminTrimmedStringList(appliesTo),
        iconValue = tenantAdminOptionalText(icon),
        colorValue = tenantAdminOptionalText(color);

  final TenantAdminRequiredTextValue idValue;
  final TenantAdminRequiredTextValue slugValue;
  final TenantAdminRequiredTextValue nameValue;
  final TenantAdminTrimmedStringListValue appliesToValue;
  final TenantAdminOptionalTextValue iconValue;
  final TenantAdminOptionalTextValue colorValue;

  String get id => idValue.value;
  String get slug => slugValue.value;
  String get name => nameValue.value;
  List<String> get appliesTo => appliesToValue.value;
  String? get icon => iconValue.nullableValue;
  String? get color => colorValue.nullableValue;
}
