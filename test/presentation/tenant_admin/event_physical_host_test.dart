import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'event picker requests the backend-owned physical host candidate set',
    () {
      expect(
        TenantAdminEventAccountProfileCandidateType.physicalHost.apiValue,
        'physical_host',
      );
      expect(
        TenantAdminEventAccountProfileCandidateType
            .relatedAccountProfile
            .apiValue,
        'related_account_profile',
      );
    },
  );

  test('physical host and map values remain independent backend values', () {
    final capabilities = tenantAdminProfileTypeCapabilitiesFromRaw(
      <String, TenantAdminProfileTypeCapabilityValue>{
        'location_policy': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: 'optional',
        ),
        'is_map_poi_enabled': tenantAdminProfileTypeCapabilityValueFromRaw(
          value: false,
        ),
        'is_physical_host_enabled':
            tenantAdminProfileTypeCapabilityValueFromRaw(value: true),
      },
    );

    expect(capabilities.allowsLocation, isTrue);
    expect(capabilities.isMapPoiEnabled, isFalse);
    expect(capabilities.isPhysicalHostEnabled, isTrue);
  });
}
