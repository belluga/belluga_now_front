import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminStaticProfileTypeDefinition
    tenantAdminStaticProfileTypeDefinitionFromRaw({
  required Object? type,
  required Object? label,
  required Object? allowedTaxonomies,
  required TenantAdminStaticProfileTypeCapabilities capabilities,
  TenantAdminPoiVisual? poiVisual,
}) {
  return TenantAdminStaticProfileTypeDefinition(
    typeValue: tenantAdminRequiredText(type),
    labelValue: tenantAdminRequiredText(label),
    allowedTaxonomiesValue: tenantAdminTrimmedStringList(allowedTaxonomies),
    capabilities: capabilities,
    poiVisual: poiVisual,
  );
}
