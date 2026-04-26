import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_location_preference.dart';

class ProximityPreference {
  const ProximityPreference({
    required this.maxDistanceMetersValue,
    required this.locationPreference,
  });

  final DistanceInMetersValue maxDistanceMetersValue;
  final ProximityLocationPreference locationPreference;

  double get maxDistanceMeters => maxDistanceMetersValue.value;

  ProximityPreference copyWith({
    DistanceInMetersValue? maxDistanceMetersValue,
    ProximityLocationPreference? locationPreference,
  }) {
    return ProximityPreference(
      maxDistanceMetersValue:
          maxDistanceMetersValue ?? this.maxDistanceMetersValue,
      locationPreference: locationPreference ?? this.locationPreference,
    );
  }
}
