import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

typedef TenantAdminTaxonomyDefinitionPrimString = String;
typedef TenantAdminTaxonomyDefinitionPrimInt = int;
typedef TenantAdminTaxonomyDefinitionPrimBool = bool;
typedef TenantAdminTaxonomyDefinitionPrimDouble = double;
typedef TenantAdminTaxonomyDefinitionPrimDateTime = DateTime;
typedef TenantAdminTaxonomyDefinitionPrimDynamic = dynamic;

class TenantAdminTaxonomyDefinition {
  TenantAdminTaxonomyDefinition({
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

  TenantAdminTaxonomyDefinitionPrimString get id => idValue.value;
  TenantAdminTaxonomyDefinitionPrimString get slug => slugValue.value;
  TenantAdminTaxonomyDefinitionPrimString get name => nameValue.value;
  List<TenantAdminTaxonomyDefinitionPrimString> get appliesTo =>
      appliesToValue.value;
  TenantAdminTaxonomyDefinitionPrimString? get icon => iconValue.nullableValue;
  TenantAdminTaxonomyDefinitionPrimString? get color =>
      colorValue.nullableValue;

  TenantAdminTaxonomyDefinitionPrimBool appliesToTarget(
      TenantAdminTaxonomyDefinitionPrimString target) {
    return appliesTo.contains(target);
  }
}
