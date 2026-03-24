export 'location_tracking_mode.dart';
export 'location_resolution_phase.dart';

import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/location_resolution_phase.dart';
import 'package:belluga_now/domain/repositories/location_tracking_mode.dart';
import 'package:stream_value/core/stream_value.dart';

typedef UserLocationRepositoryContractPrimString = String;
typedef UserLocationRepositoryContractPrimInt = int;
typedef UserLocationRepositoryContractPrimBool = bool;
typedef UserLocationRepositoryContractPrimDouble = double;
typedef UserLocationRepositoryContractPrimDateTime = DateTime;
typedef UserLocationRepositoryContractPrimDuration = Duration;
typedef UserLocationRepositoryContractPrimDynamic = dynamic;

abstract class UserLocationRepositoryContract {
  StreamValue<CityCoordinate?> get userLocationStreamValue;
  StreamValue<CityCoordinate?> get lastKnownLocationStreamValue;
  StreamValue<UserLocationRepositoryContractPrimDateTime?>
      get lastKnownCapturedAtStreamValue;
  StreamValue<UserLocationRepositoryContractPrimDouble?>
      get lastKnownAccuracyStreamValue;
  StreamValue<UserLocationRepositoryContractPrimString?>
      get lastKnownAddressStreamValue;
  StreamValue<LocationResolutionPhase> get locationResolutionPhaseStreamValue;

  Future<void> ensureLoaded();
  Future<void> setLastKnownAddress(
      UserLocationRepositoryContractPrimString? address);

  /// Best-effort: resolves location **without** triggering permission prompts.
  /// Returns `true` when a coordinate is available after the call.
  Future<UserLocationRepositoryContractPrimBool> warmUpIfPermitted();

  /// Best-effort refresh: attempts to update the cached/live coordinate **without**
  /// triggering permission prompts. Returns `true` when a coordinate is available
  /// after the call (either cached or refreshed).
  Future<UserLocationRepositoryContractPrimBool> refreshIfPermitted({
    UserLocationRepositoryContractPrimDuration minInterval =
        const Duration(seconds: 30),
  });

  /// Resolves location, requesting permission if needed (interactive).
  /// Returns a user-facing error/warning message when location cannot be resolved.
  Future<UserLocationRepositoryContractPrimString?> resolveUserLocation();

  /// Starts a continuous location stream while the caller is active (e.g., map screen).
  /// Must be paired with [stopTracking] to avoid unnecessary battery usage.
  Future<UserLocationRepositoryContractPrimBool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  });

  /// Stops the active tracking stream, if any.
  Future<void> stopTracking();
}
