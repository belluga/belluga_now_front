import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminStaticProfileTypeCapabilities {
  TenantAdminStaticProfileTypeCapabilities({
    required TenantAdminFlagValue isPoiEnabled,
    required TenantAdminFlagValue hasBio,
    required TenantAdminFlagValue hasTaxonomies,
    required TenantAdminFlagValue hasAvatar,
    required TenantAdminFlagValue hasCover,
    required TenantAdminFlagValue hasContent,
  })  : isPoiEnabledValue = isPoiEnabled,
        hasBioValue = hasBio,
        hasTaxonomiesValue = hasTaxonomies,
        hasAvatarValue = hasAvatar,
        hasCoverValue = hasCover,
        hasContentValue = hasContent;

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
