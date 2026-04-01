export 'tenant_admin_static_profile_type_capabilities.dart';
export 'value_objects/tenant_admin_static_profile_type_values.dart';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminStaticProfileTypeDefinition {
  TenantAdminStaticProfileTypeDefinition({
    required this.typeValue,
    required this.labelValue,
    required this.allowedTaxonomiesValue,
    required this.capabilities,
    this.poiVisual,
  });

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminTrimmedStringListValue allowedTaxonomiesValue;
  final TenantAdminStaticProfileTypeCapabilities capabilities;
  final TenantAdminPoiVisual? poiVisual;

  String get type => typeValue.value;
  String get label => labelValue.value;
  TenantAdminTrimmedStringListValue get allowedTaxonomies =>
      allowedTaxonomiesValue;
}
