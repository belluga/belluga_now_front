import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminStaticProfileTypeCapabilities {
  TenantAdminStaticProfileTypeCapabilities({
    required Object isPoiEnabled,
    required Object hasBio,
    required Object hasTaxonomies,
    required Object hasAvatar,
    required Object hasCover,
    required Object hasContent,
  })  : isPoiEnabledValue = tenantAdminFlag(isPoiEnabled),
        hasBioValue = tenantAdminFlag(hasBio),
        hasTaxonomiesValue = tenantAdminFlag(hasTaxonomies),
        hasAvatarValue = tenantAdminFlag(hasAvatar),
        hasCoverValue = tenantAdminFlag(hasCover),
        hasContentValue = tenantAdminFlag(hasContent);

  final TenantAdminFlagValue isPoiEnabledValue;
  final TenantAdminFlagValue hasBioValue;
  final TenantAdminFlagValue hasTaxonomiesValue;
  final TenantAdminFlagValue hasAvatarValue;
  final TenantAdminFlagValue hasCoverValue;
  final TenantAdminFlagValue hasContentValue;

  bool get isPoiEnabled => isPoiEnabledValue.value;
  bool get hasBio => hasBioValue.value;
  bool get hasTaxonomies => hasTaxonomiesValue.value;
  bool get hasAvatar => hasAvatarValue.value;
  bool get hasCover => hasCoverValue.value;
  bool get hasContent => hasContentValue.value;
}
