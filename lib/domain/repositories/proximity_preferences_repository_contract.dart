import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/proximity_preferences/proximity_preference.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class ProximityPreferencesRepositoryContract {
  final StreamValue<ProximityPreference?> _proximityPreferenceStreamValue =
      StreamValue<ProximityPreference?>(defaultValue: null);

  StreamValue<ProximityPreference?> get proximityPreferenceStreamValue =>
      _proximityPreferenceStreamValue;

  ProximityPreference? get proximityPreference =>
      _proximityPreferenceStreamValue.value;

  void seedFromLocalMirror() {}

  Future<void> syncAfterIdentityReady() async {}

  Future<void> updateMaxDistanceMeters(
    DistanceInMetersValue meters,
  ) async {}

  Future<void> setLiveDeviceLocation() async {}

  Future<void> setFixedReference({
    required FixedLocationReference fixedReference,
  }) async {}

  void setCurrentPreference(ProximityPreference? preference) {
    _proximityPreferenceStreamValue.addValue(preference);
  }
}
