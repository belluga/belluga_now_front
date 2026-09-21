import 'package:belluga_now/domain/partners/value_objects/profile_type_flag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_location_policy_value.dart';

class ProfileTypeCapabilities {
  ProfileTypeCapabilities({
    required this.isPubliclyDiscoverableValue,
    required this.isFavoritableValue,
    required this.locationPolicyValue,
    required this.isMapPoiEnabledValue,
    required this.isReferenceLocationEnabledValue,
    required this.hasBioValue,
    required this.hasTaxonomiesValue,
    required this.hasAvatarValue,
    required this.hasCoverValue,
    required this.hasEventsValue,
    required this.hasGalleryValue,
    required this.hasNestedProfileGroupsValue,
    required this.hasContactChannelsValue,
    required this.hasExternalLinksValue,
  });

  final ProfileTypeFlagValue isPubliclyDiscoverableValue;
  final ProfileTypeFlagValue isFavoritableValue;
  final ProfileTypeLocationPolicyValue locationPolicyValue;
  final ProfileTypeFlagValue isMapPoiEnabledValue;
  final ProfileTypeFlagValue isReferenceLocationEnabledValue;
  final ProfileTypeFlagValue hasBioValue;
  final ProfileTypeFlagValue hasTaxonomiesValue;
  final ProfileTypeFlagValue hasAvatarValue;
  final ProfileTypeFlagValue hasCoverValue;
  final ProfileTypeFlagValue hasEventsValue;
  final ProfileTypeFlagValue hasGalleryValue;
  final ProfileTypeFlagValue hasNestedProfileGroupsValue;
  final ProfileTypeFlagValue hasContactChannelsValue;
  final ProfileTypeFlagValue hasExternalLinksValue;

  bool get isPubliclyDiscoverable => isPubliclyDiscoverableValue.value;
  bool get isFavoritable => isFavoritableValue.value;
  String get locationPolicy => locationPolicyValue.value;
  bool get allowsLocation => locationPolicyValue.allowsLocation;
  bool get requiresLocation => locationPolicyValue.requiresLocation;
  bool get isMapPoiEnabled => isMapPoiEnabledValue.value;
  bool get isReferenceLocationEnabled => isReferenceLocationEnabledValue.value;
  bool get hasBio => hasBioValue.value;
  bool get hasTaxonomies => hasTaxonomiesValue.value;
  bool get hasAvatar => hasAvatarValue.value;
  bool get hasCover => hasCoverValue.value;
  bool get hasEvents => hasEventsValue.value;
  bool get hasGallery => hasGalleryValue.value;
  bool get hasNestedProfileGroups => hasNestedProfileGroupsValue.value;
  bool get hasContactChannels => hasContactChannelsValue.value;
  bool get hasExternalLinks => hasExternalLinksValue.value;
}
