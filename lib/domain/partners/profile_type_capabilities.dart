import 'package:belluga_now/domain/partners/value_objects/profile_type_flag_value.dart';

class ProfileTypeCapabilities {
  ProfileTypeCapabilities({
    required this.isFavoritableValue,
    required this.isPoiEnabledValue,
    ProfileTypeFlagValue? isReferenceLocationEnabledValue,
    required this.hasBioValue,
    required this.hasContentValue,
    required this.hasTaxonomiesValue,
    required this.hasAvatarValue,
    required this.hasCoverValue,
    required this.hasEventsValue,
  }) : isReferenceLocationEnabledValue =
            isReferenceLocationEnabledValue ?? ProfileTypeFlagValue(false);

  final ProfileTypeFlagValue isFavoritableValue;
  final ProfileTypeFlagValue isPoiEnabledValue;
  final ProfileTypeFlagValue isReferenceLocationEnabledValue;
  final ProfileTypeFlagValue hasBioValue;
  final ProfileTypeFlagValue hasContentValue;
  final ProfileTypeFlagValue hasTaxonomiesValue;
  final ProfileTypeFlagValue hasAvatarValue;
  final ProfileTypeFlagValue hasCoverValue;
  final ProfileTypeFlagValue hasEventsValue;

  bool get isFavoritable => isFavoritableValue.value;
  bool get isPoiEnabled => isPoiEnabledValue.value;
  bool get isReferenceLocationEnabled =>
      isPoiEnabled && isReferenceLocationEnabledValue.value;
  bool get hasBio => hasBioValue.value;
  bool get hasContent => hasContentValue.value;
  bool get hasTaxonomies => hasTaxonomiesValue.value;
  bool get hasAvatar => hasAvatarValue.value;
  bool get hasCover => hasCoverValue.value;
  bool get hasEvents => hasEventsValue.value;
}
