import 'package:belluga_now/domain/app_data/location_origin_reason.dart';
import 'package:value_object_pattern/value_object.dart';

class LocationOriginReasonValue extends ValueObject<LocationOriginReason> {
  LocationOriginReasonValue({
    super.defaultValue = LocationOriginReason.live,
    super.isRequired = false,
  });

  factory LocationOriginReasonValue.fromRaw(
    Object? raw, {
    LocationOriginReason defaultValue = LocationOriginReason.live,
    bool isRequired = false,
  }) {
    final value = LocationOriginReasonValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is LocationOriginReason) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  LocationOriginReason doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    return switch (normalized) {
      'outsiderange' => LocationOriginReason.outsideRange,
      'unavailable' => LocationOriginReason.unavailable,
      'userpreference' => LocationOriginReason.userPreference,
      'live' => LocationOriginReason.live,
      _ => defaultValue,
    };
  }
}
