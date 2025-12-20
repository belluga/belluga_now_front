import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:stream_value/core/stream_value.dart';

enum LocationTrackingMode {
  /// High accuracy, foreground usage (e.g., map open).
  mapForeground,

  /// Low accuracy / lower update rate (e.g., background-ish UI needs).
  lowPower,
}

abstract class UserLocationRepositoryContract {
  StreamValue<CityCoordinate?> get userLocationStreamValue;
  StreamValue<CityCoordinate?> get lastKnownLocationStreamValue;
  StreamValue<DateTime?> get lastKnownCapturedAtStreamValue;
  StreamValue<String?> get lastKnownAddressStreamValue;

  Future<void> ensureLoaded();
  Future<void> setLastKnownAddress(String? address);

  /// Best-effort: resolves location **without** triggering permission prompts.
  /// Returns `true` when a coordinate is available after the call.
  Future<bool> warmUpIfPermitted();

  /// Best-effort refresh: attempts to update the cached/live coordinate **without**
  /// triggering permission prompts. Returns `true` when a coordinate is available
  /// after the call (either cached or refreshed).
  Future<bool> refreshIfPermitted({
    Duration minInterval = const Duration(seconds: 30),
  });

  /// Resolves location, requesting permission if needed (interactive).
  /// Returns a user-facing error/warning message when location cannot be resolved.
  Future<String?> resolveUserLocation();

  /// Starts a continuous location stream while the caller is active (e.g., map screen).
  /// Must be paired with [stopTracking] to avoid unnecessary battery usage.
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  });

  /// Stops the active tracking stream, if any.
  Future<void> stopTracking();
}
