import 'package:belluga_now/domain/app_data/home_location_origin_mode.dart';
import 'package:belluga_now/domain/app_data/home_location_origin_reason.dart';
import 'package:belluga_now/domain/app_data/value_object/home_location_origin_mode_value.dart';
import 'package:belluga_now/domain/app_data/value_object/home_location_origin_reason_value.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

class HomeLocationOriginSettings {
  HomeLocationOriginSettings({
    required this.modeValue,
    required this.reasonValue,
    required this.fixedLocationReference,
  });

  factory HomeLocationOriginSettings.live() {
    return HomeLocationOriginSettings(
      modeValue: HomeLocationOriginModeValue.fromRaw(
        HomeLocationOriginMode.live,
      ),
      reasonValue: HomeLocationOriginReasonValue.fromRaw(
        HomeLocationOriginReason.live,
      ),
      fixedLocationReference: null,
    );
  }

  factory HomeLocationOriginSettings.fixed({
    required CityCoordinate fixedLocationReference,
    required HomeLocationOriginReason reason,
  }) {
    return HomeLocationOriginSettings(
      modeValue: HomeLocationOriginModeValue.fromRaw(
        HomeLocationOriginMode.fixed,
      ),
      reasonValue: HomeLocationOriginReasonValue.fromRaw(reason),
      fixedLocationReference: fixedLocationReference,
    );
  }

  final HomeLocationOriginModeValue modeValue;
  final HomeLocationOriginReasonValue reasonValue;
  final CityCoordinate? fixedLocationReference;

  bool get usesLiveLocation => modeValue.value == HomeLocationOriginMode.live;
  bool get usesFixedReference => modeValue.value == HomeLocationOriginMode.fixed;

  HomeLocationOriginReason get reason => reasonValue.value;

  bool sameAs(HomeLocationOriginSettings? other) {
    if (other == null) {
      return false;
    }
    return usesLiveLocation == other.usesLiveLocation &&
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
