import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capability_key.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_profile_type_capability_values.dart';

export 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminProfileTypeCapabilities {
  factory TenantAdminProfileTypeCapabilities({
    TenantAdminFlagValue? isQueryable,
    TenantAdminFlagValue? isPubliclyNavigable,
    TenantAdminFlagValue? isPubliclyDiscoverable,
    TenantAdminFlagValue? isInviteable,
    required TenantAdminFlagValue isFavoritable,
    required TenantAdminFlagValue isPoiEnabled,
    TenantAdminFlagValue? isReferenceLocationEnabled,
    required TenantAdminFlagValue hasBio,
    required TenantAdminFlagValue hasContent,
    required TenantAdminFlagValue hasTaxonomies,
    required TenantAdminFlagValue hasAvatar,
    required TenantAdminFlagValue hasCover,
    required TenantAdminFlagValue hasEvents,
    TenantAdminFlagValue? hasGallery,
    TenantAdminFlagValue? hasNestedProfileGroups,
  }) {
    final normalized = TenantAdminProfileTypeCapabilityStateValue({
      if (isQueryable != null)
        TenantAdminProfileTypeCapabilityKey.isQueryable.apiValue:
            isQueryable.value,
      if (isPubliclyNavigable != null)
        TenantAdminProfileTypeCapabilityKey.isPubliclyNavigable.apiValue:
            isPubliclyNavigable.value,
      if (isPubliclyDiscoverable != null)
        TenantAdminProfileTypeCapabilityKey.isPubliclyDiscoverable.apiValue:
            isPubliclyDiscoverable.value,
      if (isInviteable != null)
        TenantAdminProfileTypeCapabilityKey.isInviteable.apiValue:
            isInviteable.value,
      TenantAdminProfileTypeCapabilityKey.isFavoritable.apiValue:
          isFavoritable.value,
      TenantAdminProfileTypeCapabilityKey.isPoiEnabled.apiValue:
          isPoiEnabled.value,
      if (isReferenceLocationEnabled != null)
        TenantAdminProfileTypeCapabilityKey.isReferenceLocationEnabled.apiValue:
            isReferenceLocationEnabled.value,
      TenantAdminProfileTypeCapabilityKey.hasBio.apiValue: hasBio.value,
      TenantAdminProfileTypeCapabilityKey.hasContent.apiValue: hasContent.value,
      TenantAdminProfileTypeCapabilityKey.hasTaxonomies.apiValue:
          hasTaxonomies.value,
      TenantAdminProfileTypeCapabilityKey.hasAvatar.apiValue: hasAvatar.value,
      TenantAdminProfileTypeCapabilityKey.hasCover.apiValue: hasCover.value,
      TenantAdminProfileTypeCapabilityKey.hasEvents.apiValue: hasEvents.value,
      if (hasGallery != null)
        TenantAdminProfileTypeCapabilityKey.hasGallery.apiValue:
            hasGallery.value,
      if (hasNestedProfileGroups != null)
        TenantAdminProfileTypeCapabilityKey.hasNestedProfileGroups.apiValue:
            hasNestedProfileGroups.value,
    }).normalized();

    return TenantAdminProfileTypeCapabilities._(
      isQueryable: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.isQueryable,
      ),
      isPubliclyNavigable: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.isPubliclyNavigable,
      ),
      isPubliclyDiscoverable: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.isPubliclyDiscoverable,
      ),
      isInviteable: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.isInviteable,
      ),
      isFavoritable: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.isFavoritable,
      ),
      isPoiEnabled: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.isPoiEnabled,
      ),
      isReferenceLocationEnabled: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.isReferenceLocationEnabled,
      ),
      hasBio: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.hasBio,
      ),
      hasContent: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.hasContent,
      ),
      hasTaxonomies: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.hasTaxonomies,
      ),
      hasAvatar: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.hasAvatar,
      ),
      hasCover: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.hasCover,
      ),
      hasEvents: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.hasEvents,
      ),
      hasGallery: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.hasGallery,
      ),
      hasNestedProfileGroups: normalized.flagValue(
        TenantAdminProfileTypeCapabilityKey.hasNestedProfileGroups,
      ),
    );
  }

  TenantAdminProfileTypeCapabilities._({
    required TenantAdminFlagValue isQueryable,
    required TenantAdminFlagValue isPubliclyNavigable,
    required TenantAdminFlagValue isPubliclyDiscoverable,
    required TenantAdminFlagValue isInviteable,
    required TenantAdminFlagValue isFavoritable,
    required TenantAdminFlagValue isPoiEnabled,
    required TenantAdminFlagValue isReferenceLocationEnabled,
    required TenantAdminFlagValue hasBio,
    required TenantAdminFlagValue hasContent,
    required TenantAdminFlagValue hasTaxonomies,
    required TenantAdminFlagValue hasAvatar,
    required TenantAdminFlagValue hasCover,
    required TenantAdminFlagValue hasEvents,
    required TenantAdminFlagValue hasGallery,
    required TenantAdminFlagValue hasNestedProfileGroups,
  })  : isQueryableValue = isQueryable,
        isPubliclyNavigableValue = isPubliclyNavigable,
        isPubliclyDiscoverableValue = isPubliclyDiscoverable,
        isInviteableValue = isInviteable,
        isFavoritableValue = isFavoritable,
        isPoiEnabledValue = isPoiEnabled,
        isReferenceLocationEnabledValue = isReferenceLocationEnabled,
        hasBioValue = hasBio,
        hasContentValue = hasContent,
        hasTaxonomiesValue = hasTaxonomies,
        hasAvatarValue = hasAvatar,
        hasCoverValue = hasCover,
        hasEventsValue = hasEvents,
        hasGalleryValue = hasGallery,
        hasNestedProfileGroupsValue = hasNestedProfileGroups;

  final TenantAdminFlagValue isQueryableValue;
  final TenantAdminFlagValue isPubliclyNavigableValue;
  final TenantAdminFlagValue isPubliclyDiscoverableValue;
  final TenantAdminFlagValue isInviteableValue;
  final TenantAdminFlagValue isFavoritableValue;
  final TenantAdminFlagValue isPoiEnabledValue;
  final TenantAdminFlagValue isReferenceLocationEnabledValue;
  final TenantAdminFlagValue hasBioValue;
  final TenantAdminFlagValue hasContentValue;
  final TenantAdminFlagValue hasTaxonomiesValue;
  final TenantAdminFlagValue hasAvatarValue;
  final TenantAdminFlagValue hasCoverValue;
  final TenantAdminFlagValue hasEventsValue;
  final TenantAdminFlagValue hasGalleryValue;
  final TenantAdminFlagValue hasNestedProfileGroupsValue;

  bool get isQueryable => isQueryableValue.value;
  bool get isPubliclyNavigable => isPubliclyNavigableValue.value;
  bool get isPubliclyDiscoverable => isPubliclyDiscoverableValue.value;
  bool get isInviteable => isInviteableValue.value;
  bool get isFavoritable => isFavoritableValue.value;
  bool get isPoiEnabled => isPoiEnabledValue.value;
  bool get isReferenceLocationEnabled => isReferenceLocationEnabledValue.value;
  bool get hasBio => hasBioValue.value;
  bool get hasContent => hasContentValue.value;
  bool get hasTaxonomies => hasTaxonomiesValue.value;
  bool get hasAvatar => hasAvatarValue.value;
  bool get hasCover => hasCoverValue.value;
  bool get hasEvents => hasEventsValue.value;
  bool get hasGallery => hasGalleryValue.value;
  bool get hasNestedProfileGroups => hasNestedProfileGroupsValue.value;

  TenantAdminProfileTypeCapabilityStateValue toCapabilityMap() {
    return TenantAdminProfileTypeCapabilityStateValue({
      TenantAdminProfileTypeCapabilityKey.isQueryable.apiValue:
          isQueryableValue.value,
      TenantAdminProfileTypeCapabilityKey.isPubliclyNavigable.apiValue:
          isPubliclyNavigableValue.value,
      TenantAdminProfileTypeCapabilityKey.isPubliclyDiscoverable.apiValue:
          isPubliclyDiscoverableValue.value,
      TenantAdminProfileTypeCapabilityKey.isInviteable.apiValue:
          isInviteableValue.value,
      TenantAdminProfileTypeCapabilityKey.isFavoritable.apiValue:
          isFavoritableValue.value,
      TenantAdminProfileTypeCapabilityKey.isPoiEnabled.apiValue:
          isPoiEnabledValue.value,
      TenantAdminProfileTypeCapabilityKey.isReferenceLocationEnabled.apiValue:
          isReferenceLocationEnabledValue.value,
      TenantAdminProfileTypeCapabilityKey.hasBio.apiValue: hasBioValue.value,
      TenantAdminProfileTypeCapabilityKey.hasContent.apiValue:
          hasContentValue.value,
      TenantAdminProfileTypeCapabilityKey.hasTaxonomies.apiValue:
          hasTaxonomiesValue.value,
      TenantAdminProfileTypeCapabilityKey.hasAvatar.apiValue:
          hasAvatarValue.value,
      TenantAdminProfileTypeCapabilityKey.hasCover.apiValue:
          hasCoverValue.value,
      TenantAdminProfileTypeCapabilityKey.hasEvents.apiValue:
          hasEventsValue.value,
      TenantAdminProfileTypeCapabilityKey.hasGallery.apiValue:
          hasGalleryValue.value,
      TenantAdminProfileTypeCapabilityKey.hasNestedProfileGroups.apiValue:
          hasNestedProfileGroupsValue.value,
    }).normalized();
  }
}
