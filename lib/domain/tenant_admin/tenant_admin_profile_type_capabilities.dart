import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminProfileTypeCapabilities {
  TenantAdminProfileTypeCapabilities({
    required Object isFavoritable,
    required Object isPoiEnabled,
    required Object hasBio,
    required Object hasContent,
    required Object hasTaxonomies,
    required Object hasAvatar,
    required Object hasCover,
    required Object hasEvents,
  })  : isFavoritableValue = tenantAdminFlag(isFavoritable),
        isPoiEnabledValue = tenantAdminFlag(isPoiEnabled),
        hasBioValue = tenantAdminFlag(hasBio),
        hasContentValue = tenantAdminFlag(hasContent),
        hasTaxonomiesValue = tenantAdminFlag(hasTaxonomies),
        hasAvatarValue = tenantAdminFlag(hasAvatar),
        hasCoverValue = tenantAdminFlag(hasCover),
        hasEventsValue = tenantAdminFlag(hasEvents);

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
