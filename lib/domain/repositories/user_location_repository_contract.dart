import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:stream_value/core/stream_value.dart';

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

  /// Resolves location, requesting permission if needed (interactive).
  /// Returns a user-facing error/warning message when location cannot be resolved.
  Future<String?> resolveUserLocation();
}
