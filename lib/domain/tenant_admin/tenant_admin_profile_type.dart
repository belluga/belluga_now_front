export 'tenant_admin_profile_type_capabilities.dart';
export 'value_objects/tenant_admin_profile_type_values.dart';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminProfileTypeDefinition {
  TenantAdminProfileTypeDefinition({
    required this.typeValue,
    required this.labelValue,
    TenantAdminRequiredTextValue? pluralLabelValue,
    required this.allowedTaxonomiesValue,
    required this.capabilities,
    TenantAdminPoiVisual? visual,
    @Deprecated('Use visual instead.') TenantAdminPoiVisual? poiVisual,
  })  : pluralLabelValue = pluralLabelValue ?? labelValue,
        visual = visual ?? poiVisual;

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminRequiredTextValue pluralLabelValue;
  final TenantAdminTrimmedStringListValue allowedTaxonomiesValue;
  final TenantAdminProfileTypeCapabilities capabilities;
  final TenantAdminPoiVisual? visual;

  String get type => typeValue.value;
  String get label => labelValue.value;
  String get pluralLabel => pluralLabelValue.value;
  TenantAdminTrimmedStringListValue get allowedTaxonomies =>
      allowedTaxonomiesValue;

  @Deprecated('Use visual instead.')
  TenantAdminPoiVisual? get poiVisual => visual;
}
