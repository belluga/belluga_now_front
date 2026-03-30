export 'value_objects/tenant_admin_taxonomy_values.dart';

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

  TenantAdminTaxonomyDefinitionPrimString get id => idValue.value;
  TenantAdminTaxonomyDefinitionPrimString get slug => slugValue.value;
  TenantAdminTaxonomyDefinitionPrimString get name => nameValue.value;
  TenantAdminTrimmedStringListValue get appliesTo => appliesToValue;
  TenantAdminTaxonomyDefinitionPrimString? get icon => iconValue.nullableValue;
  TenantAdminTaxonomyDefinitionPrimString? get color =>
      colorValue.nullableValue;

  TenantAdminTaxonomyDefinitionPrimBool appliesToTarget(
    TenantAdminRequiredTextValue targetValue,
  ) {
    return appliesTo.contains(targetValue.value);
  }

  TenantAdminTaxonomyDefinitionPrimBool appliesToAccountProfile() {
    return appliesToTarget(tenantAdminRequiredText('account_profile'));
  }

  TenantAdminTaxonomyDefinitionPrimBool appliesToStaticAsset() {
    return appliesToTarget(tenantAdminRequiredText('static_asset'));
  }

  TenantAdminTaxonomyDefinitionPrimBool appliesToEvent() {
    return appliesToTarget(tenantAdminRequiredText('event'));
  }
}
