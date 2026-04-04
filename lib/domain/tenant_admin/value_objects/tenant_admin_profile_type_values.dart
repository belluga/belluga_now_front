import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

TenantAdminProfileTypeDefinition tenantAdminProfileTypeDefinitionFromRaw({
  required Object? type,
  required Object? label,
  Object? pluralLabel,
  required Object? allowedTaxonomies,
  required TenantAdminProfileTypeCapabilities capabilities,
  TenantAdminPoiVisual? visual,
  @Deprecated('Use visual instead.') TenantAdminPoiVisual? poiVisual,
}) {
  return TenantAdminProfileTypeDefinition(
    typeValue: tenantAdminRequiredText(type),
    labelValue: tenantAdminRequiredText(label),
    pluralLabelValue: tenantAdminRequiredText(pluralLabel ?? label),
    allowedTaxonomiesValue: tenantAdminTrimmedStringList(allowedTaxonomies),
    capabilities: capabilities,
    visual: visual ?? poiVisual,
  );
}
