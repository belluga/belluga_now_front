import 'package:belluga_now/domain/proximity_preferences/fixed_location_reference.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_location_preference_mode.dart';

class ProximityLocationPreference {
  const ProximityLocationPreference.liveDeviceLocation()
      : mode = ProximityLocationPreferenceMode.liveDeviceLocation,
        fixedReference = null;

  const ProximityLocationPreference.fixedReference({
    required this.fixedReference,
  }) : mode = ProximityLocationPreferenceMode.fixedReference;

  final ProximityLocationPreferenceMode mode;
  final FixedLocationReference? fixedReference;

  bool get usesLiveDeviceLocation =>
      mode == ProximityLocationPreferenceMode.liveDeviceLocation;

  bool get usesFixedReference =>
      mode == ProximityLocationPreferenceMode.fixedReference &&
      fixedReference != null;
}
