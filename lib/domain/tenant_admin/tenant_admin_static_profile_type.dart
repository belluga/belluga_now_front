export 'tenant_admin_static_profile_type_capabilities.dart';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminStaticProfileTypeDefinition {
  TenantAdminStaticProfileTypeDefinition({
    required Object type,
    required Object label,
    required Object allowedTaxonomies,
    required this.capabilities,
    this.poiVisual,
  })  : typeValue = tenantAdminRequiredText(type),
        labelValue = tenantAdminRequiredText(label),
        allowedTaxonomiesValue = tenantAdminTrimmedStringList(allowedTaxonomies);

  final TenantAdminRequiredTextValue typeValue;
  final TenantAdminRequiredTextValue labelValue;
  final TenantAdminTrimmedStringListValue allowedTaxonomiesValue;
  final TenantAdminStaticProfileTypeCapabilities capabilities;
  final TenantAdminPoiVisual? poiVisual;

  String get type => typeValue.value;
  String get label => labelValue.value;
  List<String> get allowedTaxonomies => allowedTaxonomiesValue.value;
}
