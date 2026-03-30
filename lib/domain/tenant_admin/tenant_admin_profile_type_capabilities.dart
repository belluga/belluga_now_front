import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminProfileTypeCapabilities {
  TenantAdminProfileTypeCapabilities({
    required TenantAdminFlagValue isFavoritable,
    required TenantAdminFlagValue isPoiEnabled,
    required TenantAdminFlagValue hasBio,
    required TenantAdminFlagValue hasContent,
    required TenantAdminFlagValue hasTaxonomies,
    required TenantAdminFlagValue hasAvatar,
    required TenantAdminFlagValue hasCover,
    required TenantAdminFlagValue hasEvents,
  })  : isFavoritableValue = isFavoritable,
        isPoiEnabledValue = isPoiEnabled,
        hasBioValue = hasBio,
        hasContentValue = hasContent,
        hasTaxonomiesValue = hasTaxonomies,
        hasAvatarValue = hasAvatar,
        hasCoverValue = hasCover,
        hasEventsValue = hasEvents;

  final TenantAdminFlagValue isFavoritableValue;
  final TenantAdminFlagValue isPoiEnabledValue;
  final TenantAdminFlagValue hasBioValue;
  final TenantAdminFlagValue hasContentValue;
  final TenantAdminFlagValue hasTaxonomiesValue;
  final TenantAdminFlagValue hasAvatarValue;
  final TenantAdminFlagValue hasCoverValue;
  final TenantAdminFlagValue hasEventsValue;

  bool get isFavoritable => isFavoritableValue.value;
  bool get isPoiEnabled => isPoiEnabledValue.value;
  bool get hasBio => hasBioValue.value;
  bool get hasContent => hasContentValue.value;
  bool get hasTaxonomies => hasTaxonomiesValue.value;
  bool get hasAvatar => hasAvatarValue.value;
  bool get hasCover => hasCoverValue.value;
  bool get hasEvents => hasEventsValue.value;
}
