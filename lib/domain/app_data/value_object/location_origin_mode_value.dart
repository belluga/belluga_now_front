import 'package:belluga_now/domain/app_data/location_origin_mode.dart';
import 'package:value_object_pattern/value_object.dart';

class LocationOriginModeValue extends ValueObject<LocationOriginMode> {
  LocationOriginModeValue({
    super.defaultValue = LocationOriginMode.userLiveLocation,
    super.isRequired = false,
  });

  factory LocationOriginModeValue.fromRaw(
    Object? raw, {
    LocationOriginMode defaultValue = LocationOriginMode.userLiveLocation,
    bool isRequired = false,
  }) {
    final value = LocationOriginModeValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is LocationOriginMode) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  LocationOriginMode doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    return switch (normalized) {
      'tenantdefaultlocation' => LocationOriginMode.tenantDefaultLocation,
      'userfixedlocation' => LocationOriginMode.userFixedLocation,
      'userlivelocation' => LocationOriginMode.userLiveLocation,
      _ => defaultValue,
    };
  }
}
