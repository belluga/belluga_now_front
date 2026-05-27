import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/proximity_preferences/fixed_location_reference_source_kind.dart';
import 'package:belluga_now/domain/proximity_preferences/fixed_location_reference_status.dart';
import 'package:belluga_now/domain/proximity_preferences/fixed_location_reference_status_reason.dart';
import 'package:belluga_now/domain/proximity_preferences/value_objects/proximity_preference_optional_text_value.dart';

class FixedLocationReference {
  const FixedLocationReference({
    required this.sourceKind,
    required this.coordinate,
    this.labelValue,
    this.entityNamespaceValue,
    this.entityTypeValue,
    this.entityIdValue,
    this.referenceStatus = FixedLocationReferenceStatus.active,
    this.referenceStatusReason = FixedLocationReferenceStatusReason.eligible,
    this.blockedCapabilityKeyValue,
  });

  final FixedLocationReferenceSourceKind sourceKind;
  final CityCoordinate coordinate;
  final ProximityPreferenceOptionalTextValue? labelValue;
  final ProximityPreferenceOptionalTextValue? entityNamespaceValue;
  final ProximityPreferenceOptionalTextValue? entityTypeValue;
  final ProximityPreferenceOptionalTextValue? entityIdValue;
  final FixedLocationReferenceStatus referenceStatus;
  final FixedLocationReferenceStatusReason referenceStatusReason;
  final ProximityPreferenceOptionalTextValue? blockedCapabilityKeyValue;

  String? get label => labelValue?.nullableValue;
  String? get entityNamespace => entityNamespaceValue?.nullableValue;
  String? get entityType => entityTypeValue?.nullableValue;
  String? get entityId => entityIdValue?.nullableValue;
  String? get blockedCapabilityKey => blockedCapabilityKeyValue?.nullableValue;
  bool get isActive => referenceStatus == FixedLocationReferenceStatus.active;
  bool get isDisabled =>
      referenceStatus == FixedLocationReferenceStatus.disabled;
}
