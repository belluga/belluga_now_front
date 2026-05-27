import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';

class ProximityPreferenceDTO {
  ProximityPreferenceDTO({
    required this.maxDistanceMeters,
    required this.mode,
    this.useReferencePointForRoutes,
    this.fixedReference,
  });

  final int maxDistanceMeters;
  final String mode;
  final bool? useReferencePointForRoutes;
  final Map<String, dynamic>? fixedReference;

  factory ProximityPreferenceDTO.fromJson(Map<String, dynamic> json) {
    final locationPreference =
        json['location_preference'] as Map<String, dynamic>? ??
            const <String, dynamic>{};

    return ProximityPreferenceDTO(
      maxDistanceMeters: (json['max_distance_meters'] as num?)?.round() ?? 0,
      mode: locationPreference['mode'] as String? ?? 'live_device_location',
      useReferencePointForRoutes: _nullableBool(
        json['use_reference_point_for_routes'],
      ),
      fixedReference:
          locationPreference['fixed_reference'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(
                  locationPreference['fixed_reference'] as Map,
                )
              : null,
    );
  }

  factory ProximityPreferenceDTO.fromDomain(ProximityPreference preference) {
    final fixedReference = preference.locationPreference.fixedReference;

    return ProximityPreferenceDTO(
      maxDistanceMeters: preference.maxDistanceMetersValue.value.round(),
      mode: switch (preference.locationPreference.mode) {
        ProximityLocationPreferenceMode.liveDeviceLocation =>
          'live_device_location',
        ProximityLocationPreferenceMode.fixedReference => 'fixed_reference',
      },
      useReferencePointForRoutes: preference.useReferencePointForRoutes,
      fixedReference: fixedReference == null
          ? null
          : <String, dynamic>{
              'source_kind': switch (fixedReference.sourceKind) {
                FixedLocationReferenceSourceKind.manualCoordinate =>
                  'manual_coordinate',
                FixedLocationReferenceSourceKind.entityReference =>
                  'entity_reference',
              },
              'coordinate': <String, dynamic>{
                'lat': fixedReference.coordinate.latitude,
                'lng': fixedReference.coordinate.longitude,
              },
              'label': fixedReference.label,
              'entity_namespace': fixedReference.entityNamespace,
              'entity_type': fixedReference.entityType,
              'entity_id': fixedReference.entityId,
              'reference_status': _referenceStatusToWire(
                fixedReference.referenceStatus,
              ),
              'reference_status_reason': _referenceStatusReasonToWire(
                fixedReference.referenceStatusReason,
              ),
              'blocked_capability_key': fixedReference.blockedCapabilityKey,
            },
    );
  }

  ProximityPreference toDomain() {
    return ProximityPreference(
      maxDistanceMetersValue: DistanceInMetersValue.fromRaw(
        maxDistanceMeters,
        defaultValue: maxDistanceMeters.toDouble(),
      ),
      routeReferencePointPolicyValue: RouteReferencePointPolicyValue(
        useReferencePointForRoutes,
      ),
      locationPreference: mode == 'fixed_reference' && fixedReference != null
          ? ProximityLocationPreference.fixedReference(
              fixedReference: FixedLocationReference(
                sourceKind: switch (
                    (fixedReference?['source_kind'] as String?)?.trim()) {
                  'entity_reference' =>
                    FixedLocationReferenceSourceKind.entityReference,
                  _ => FixedLocationReferenceSourceKind.manualCoordinate,
                },
                coordinate: CityCoordinate(
                  latitudeValue: LatitudeValue()
                    ..parse(
                      (fixedReference?['coordinate'] as Map<String, dynamic>? ??
                              const <String, dynamic>{})['lat']
                          .toString(),
                    ),
                  longitudeValue: LongitudeValue()
                    ..parse(
                      (fixedReference?['coordinate'] as Map<String, dynamic>? ??
                              const <String, dynamic>{})['lng']
                          .toString(),
                    ),
                ),
                labelValue: _optionalTextValue(fixedReference?['label']),
                entityNamespaceValue: _optionalTextValue(
                  fixedReference?['entity_namespace'],
                ),
                entityTypeValue: _optionalTextValue(
                  fixedReference?['entity_type'],
                ),
                entityIdValue: _optionalTextValue(fixedReference?['entity_id']),
                referenceStatus: _referenceStatusFromWire(
                  fixedReference?['reference_status'],
                ),
                referenceStatusReason: _referenceStatusReasonFromWire(
                  fixedReference?['reference_status_reason'],
                ),
                blockedCapabilityKeyValue: _optionalTextValue(
                  fixedReference?['blocked_capability_key'],
                ),
              ),
            )
          : const ProximityLocationPreference.liveDeviceLocation(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'max_distance_meters': maxDistanceMeters,
      'use_reference_point_for_routes': useReferencePointForRoutes,
      'location_preference': <String, dynamic>{
        'mode': mode,
        'fixed_reference': fixedReference,
      },
    };
  }

  static ProximityPreferenceOptionalTextValue? _optionalTextValue(
    Object? value,
  ) {
    final normalized = ProximityPreferenceOptionalTextValue.fromRaw(value);
    return normalized.nullableValue == null ? null : normalized;
  }

  static bool? _nullableBool(Object? value) {
    if (value is bool) {
      return value;
    }
    return null;
  }

  static FixedLocationReferenceStatus _referenceStatusFromWire(Object? value) {
    return switch ((value as String?)?.trim()) {
      'disabled' => FixedLocationReferenceStatus.disabled,
      _ => FixedLocationReferenceStatus.active,
    };
  }

  static FixedLocationReferenceStatusReason _referenceStatusReasonFromWire(
    Object? value,
  ) {
    return switch ((value as String?)?.trim()) {
      'manual_coordinate' =>
        FixedLocationReferenceStatusReason.manualCoordinate,
      'source_capability_disabled' =>
        FixedLocationReferenceStatusReason.sourceCapabilityDisabled,
      _ => FixedLocationReferenceStatusReason.eligible,
    };
  }

  static String _referenceStatusToWire(FixedLocationReferenceStatus status) {
    return switch (status) {
      FixedLocationReferenceStatus.active => 'active',
      FixedLocationReferenceStatus.disabled => 'disabled',
    };
  }

  static String _referenceStatusReasonToWire(
    FixedLocationReferenceStatusReason reason,
  ) {
    return switch (reason) {
      FixedLocationReferenceStatusReason.eligible => 'eligible',
      FixedLocationReferenceStatusReason.manualCoordinate =>
        'manual_coordinate',
      FixedLocationReferenceStatusReason.sourceCapabilityDisabled =>
        'source_capability_disabled',
    };
  }
}
