import 'package:belluga_now/domain/partners/profile_type_capabilities.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_flag_value.dart';
import 'package:belluga_now/domain/partners/value_objects/profile_type_location_policy_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps public effective capability values independent', () {
    final capabilities = ProfileTypeCapabilities(
      isPubliclyDiscoverableValue: _flag(true),
      isFavoritableValue: _flag(false),
      locationPolicyValue: ProfileTypeLocationPolicyValue('optional'),
      isMapPoiEnabledValue: _flag(false),
      isReferenceLocationEnabledValue: _flag(true),
      hasBioValue: _flag(false),
      hasTaxonomiesValue: _flag(false),
      hasAvatarValue: _flag(false),
      hasCoverValue: _flag(false),
      hasEventsValue: _flag(false),
      hasGalleryValue: _flag(false),
      hasNestedProfileGroupsValue: _flag(false),
      hasContactChannelsValue: _flag(false),
      hasExternalLinksValue: _flag(false),
    );

    expect(capabilities.allowsLocation, isTrue);
    expect(capabilities.requiresLocation, isFalse);
    expect(capabilities.isMapPoiEnabled, isFalse);
    expect(capabilities.isReferenceLocationEnabled, isTrue);
    expect(capabilities.isPubliclyDiscoverable, isTrue);
    expect(capabilities.isFavoritable, isFalse);
  });

  test(
    'keeps enum values opaque and fails closed for unknown location policy',
    () {
      final policy = ProfileTypeLocationPolicyValue('future-policy');

      expect(policy.value, 'future-policy');
      expect(policy.allowsLocation, isFalse);
      expect(policy.requiresLocation, isFalse);
    },
  );
}

ProfileTypeFlagValue _flag(bool value) => ProfileTypeFlagValue(value);
