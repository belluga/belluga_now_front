import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_location_preference.dart';
import 'package:belluga_now/domain/proximity_preferences/value_objects/route_reference_point_policy_value.dart';

class ProximityPreference {
  ProximityPreference({
    required this.maxDistanceMetersValue,
    required this.locationPreference,
    RouteReferencePointPolicyValue? routeReferencePointPolicyValue,
  }) : routeReferencePointPolicyValue = routeReferencePointPolicyValue ??
            RouteReferencePointPolicyValue.prompt();

  final DistanceInMetersValue maxDistanceMetersValue;
  final ProximityLocationPreference locationPreference;
  final RouteReferencePointPolicyValue routeReferencePointPolicyValue;

  double get maxDistanceMeters => maxDistanceMetersValue.value;
  bool? get useReferencePointForRoutes => routeReferencePointPolicyValue.value;

  ProximityPreference copyWith({
    DistanceInMetersValue? maxDistanceMetersValue,
    ProximityLocationPreference? locationPreference,
    RouteReferencePointPolicyValue? routeReferencePointPolicyValue,
  }) {
    return ProximityPreference(
      maxDistanceMetersValue:
          maxDistanceMetersValue ?? this.maxDistanceMetersValue,
      locationPreference: locationPreference ?? this.locationPreference,
      routeReferencePointPolicyValue:
          routeReferencePointPolicyValue ?? this.routeReferencePointPolicyValue,
    );
  }
}
