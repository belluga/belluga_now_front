import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/proximity_preferences/fixed_location_reference_source_kind.dart';
import 'package:belluga_now/domain/proximity_preferences/value_objects/proximity_preference_optional_text_value.dart';

class FixedLocationReference {
  const FixedLocationReference({
    required this.sourceKind,
    required this.coordinate,
    this.labelValue,
    this.entityNamespaceValue,
    this.entityTypeValue,
    this.entityIdValue,
  });

  final FixedLocationReferenceSourceKind sourceKind;
  final CityCoordinate coordinate;
  final ProximityPreferenceOptionalTextValue? labelValue;
  final ProximityPreferenceOptionalTextValue? entityNamespaceValue;
  final ProximityPreferenceOptionalTextValue? entityTypeValue;
  final ProximityPreferenceOptionalTextValue? entityIdValue;

  String? get label => labelValue?.nullableValue;
  String? get entityNamespace => entityNamespaceValue?.nullableValue;
  String? get entityType => entityTypeValue?.nullableValue;
  String? get entityId => entityIdValue?.nullableValue;
}
