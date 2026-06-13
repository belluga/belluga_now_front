export 'location_tracking_mode.dart';
export 'location_resolution_phase.dart';

import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/location_resolution_phase.dart';
import 'package:belluga_now/domain/repositories/location_tracking_mode.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_bool_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_text_value.dart';
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
      UserLocationRepositoryContractTextValue? address);

  /// Best-effort: resolves location **without** triggering permission prompts.
  /// Returns `true` when a coordinate is available after the call.
  Future<UserLocationRepositoryContractPrimBool> warmUpIfPermitted();

  /// Best-effort refresh: attempts to update the cached/live coordinate **without**
  /// triggering permission prompts. Returns `true` when a coordinate is available
  /// after the call (either cached or refreshed).
  Future<UserLocationRepositoryContractPrimBool> refreshIfPermitted({
    UserLocationRepositoryContractDurationValue? minInterval,
  });

  /// Resolves a live location fix, optionally requesting permission.
  /// Callers that already own the permission boundary should pass
  /// `requestPermissionIfNeededValue: false` plus an explicit timeout.
  /// Returns a user-facing error/warning message when location cannot be resolved.
  Future<UserLocationRepositoryContractPrimString?> resolveUserLocation({
    UserLocationRepositoryContractDurationValue? timeout,
    UserLocationRepositoryContractBoolValue? requestPermissionIfNeededValue,
  });

  /// Starts a continuous location stream while the caller is active (e.g., map screen).
  /// Must be paired with [stopTracking] to avoid unnecessary battery usage.
  Future<UserLocationRepositoryContractPrimBool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  });

  /// Stops the active tracking stream, if any.
  Future<void> stopTracking();
}
