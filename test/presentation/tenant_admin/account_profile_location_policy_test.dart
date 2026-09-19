import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_account_profiles_request_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('location policy drives permitted and required presentation state', () {
    expect(_capabilities('disabled').allowsLocation, isFalse);
    expect(_capabilities('disabled').requiresLocation, isFalse);
    expect(_capabilities('optional').allowsLocation, isTrue);
    expect(_capabilities('optional').requiresLocation, isFalse);
    expect(_capabilities('required').allowsLocation, isTrue);
    expect(_capabilities('required').requiresLocation, isTrue);
  });

  test(
    'location update transport distinguishes omission clear and replacement',
    () {
      const encoder = TenantAdminAccountProfilesRequestEncoder();

      expect(encoder.encodeUpdateAccountProfile(), isNot(contains('location')));
      expect(
        encoder.encodeUpdateAccountProfile(includeLocation: true),
        containsPair('location', null),
      );
      expect(
        encoder.encodeUpdateAccountProfile(
          includeLocation: true,
          location: tenantAdminLocationFromRaw(
            latitude: -22.9,
            longitude: -43.2,
          ),
        )['location'],
        <String, double>{'lat': -22.9, 'lng': -43.2},
      );
    },
  );
}

TenantAdminProfileTypeCapabilities _capabilities(String locationPolicy) {
  return tenantAdminProfileTypeCapabilitiesFromRaw(
    <String, TenantAdminProfileTypeCapabilityValue>{
      'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
        value: locationPolicy,
      ),
    },
  );
}
