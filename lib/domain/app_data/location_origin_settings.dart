import 'package:belluga_now/domain/app_data/location_origin_mode.dart';
import 'package:belluga_now/domain/app_data/location_origin_reason.dart';
import 'package:belluga_now/domain/app_data/value_object/location_origin_mode_value.dart';
import 'package:belluga_now/domain/app_data/value_object/location_origin_reason_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

class LocationOriginSettings {
  LocationOriginSettings({
    required this.modeValue,
    required this.reasonValue,
    required this.fixedLocationReference,
  });

  factory LocationOriginSettings.userLiveLocation() {
    return LocationOriginSettings(
      modeValue: LocationOriginModeValue.fromRaw(
        LocationOriginMode.userLiveLocation,
      ),
      reasonValue: LocationOriginReasonValue.fromRaw(
        LocationOriginReason.live,
      ),
      fixedLocationReference: null,
    );
  }

  factory LocationOriginSettings.tenantDefaultLocation({
    required CityCoordinate fixedLocationReference,
    required LocationOriginReason reason,
  }) {
    return LocationOriginSettings(
      modeValue: LocationOriginModeValue.fromRaw(
        LocationOriginMode.tenantDefaultLocation,
      ),
      reasonValue: LocationOriginReasonValue.fromRaw(reason),
      fixedLocationReference: fixedLocationReference,
    );
  }

  factory LocationOriginSettings.userFixedLocation({
    required CityCoordinate fixedLocationReference,
  }) {
    return LocationOriginSettings(
      modeValue: LocationOriginModeValue.fromRaw(
        LocationOriginMode.userFixedLocation,
      ),
      reasonValue: LocationOriginReasonValue.fromRaw(
        LocationOriginReason.userPreference,
      ),
      fixedLocationReference: fixedLocationReference,
    );
  }

  final LocationOriginModeValue modeValue;
  final LocationOriginReasonValue reasonValue;
  final CityCoordinate? fixedLocationReference;

  LocationOriginMode get mode => modeValue.value;
  LocationOriginReason get reason => reasonValue.value;

  bool get usesUserLiveLocation => mode == LocationOriginMode.userLiveLocation;
  bool get usesTenantDefaultLocation =>
      mode == LocationOriginMode.tenantDefaultLocation;
  bool get usesUserFixedLocation => mode == LocationOriginMode.userFixedLocation;
  bool get usesUserFixedPreference =>
      usesUserFixedLocation && reason == LocationOriginReason.userPreference;
  bool get usesTenantDefaultOutsideRange =>
      usesTenantDefaultLocation && reason == LocationOriginReason.outsideRange;
  bool get usesTenantDefaultUnavailable =>
      usesTenantDefaultLocation && reason == LocationOriginReason.unavailable;
  bool get usesFixedReference =>
      usesTenantDefaultLocation || usesUserFixedLocation;

  bool sameAs(LocationOriginSettings? other) {
    if (other == null) {
      return false;
    }
    return mode == other.mode &&
        reason == other.reason &&
        _sameCoordinate(fixedLocationReference, other.fixedLocationReference);
  }

  static bool _sameCoordinate(
    CityCoordinate? left,
    CityCoordinate? right,
  ) {
    if (left == null && right == null) {
      return true;
    }
    if (left == null || right == null) {
      return false;
    }
    return left.latitude == right.latitude && left.longitude == right.longitude;
  }
}
