import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:belluga_now/infrastructure/dal/dto/proximity_preference_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps nullable route reference point policy', () {
    for (final value in <bool?>[null, true, false]) {
      final dto = ProximityPreferenceDTO.fromJson({
        'max_distance_meters': 25000,
        'use_reference_point_for_routes': value,
        'location_preference': {
          'mode': 'live_device_location',
          'fixed_reference': null,
        },
      });

      final preference = dto.toDomain();
      final encoded = ProximityPreferenceDTO.fromDomain(preference).toJson();

      expect(preference.useReferencePointForRoutes, value);
      expect(encoded['use_reference_point_for_routes'], value);
    }
  });

  test('maps disabled entity reference status while preserving provenance', () {
    final dto = ProximityPreferenceDTO.fromJson({
      'max_distance_meters': 25000,
      'location_preference': {
        'mode': 'fixed_reference',
        'fixed_reference': {
          'source_kind': 'entity_reference',
          'coordinate': {'lat': -20.6736, 'lng': -40.4976},
          'label': 'Hotel Base',
          'entity_namespace': 'account_profile',
          'entity_type': 'hotel',
          'entity_id': 'profile-1',
          'reference_status': 'disabled',
          'reference_status_reason': 'source_capability_disabled',
          'blocked_capability_key': 'is_poi_enabled',
        },
      },
    });

    final preference = dto.toDomain();
    final fixedReference = preference.locationPreference.fixedReference;

    expect(fixedReference, isNotNull);
    expect(
      fixedReference!.sourceKind,
      FixedLocationReferenceSourceKind.entityReference,
    );
    expect(fixedReference.coordinate.latitude, closeTo(-20.6736, 0.000001));
    expect(fixedReference.coordinate.longitude, closeTo(-40.4976, 0.000001));
    expect(fixedReference.label, 'Hotel Base');
    expect(fixedReference.entityNamespace, 'account_profile');
    expect(fixedReference.entityType, 'hotel');
    expect(fixedReference.entityId, 'profile-1');
    expect(
      fixedReference.referenceStatus,
      FixedLocationReferenceStatus.disabled,
    );
    expect(
      fixedReference.referenceStatusReason,
      FixedLocationReferenceStatusReason.sourceCapabilityDisabled,
    );
    expect(fixedReference.blockedCapabilityKey, 'is_poi_enabled');
    expect(preference.locationPreference.hasFixedReference, isTrue);
    expect(preference.locationPreference.usesFixedReference, isFalse);
  });
}
