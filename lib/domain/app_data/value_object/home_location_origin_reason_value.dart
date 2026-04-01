import 'package:belluga_now/domain/app_data/home_location_origin_reason.dart';
import 'package:value_object_pattern/value_object.dart';

class HomeLocationOriginReasonValue
    extends ValueObject<HomeLocationOriginReason> {
  HomeLocationOriginReasonValue({
    super.defaultValue = HomeLocationOriginReason.live,
    super.isRequired = false,
  });

  factory HomeLocationOriginReasonValue.fromRaw(
    Object? raw, {
    HomeLocationOriginReason defaultValue = HomeLocationOriginReason.live,
    bool isRequired = false,
  }) {
    final value = HomeLocationOriginReasonValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is HomeLocationOriginReason) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  HomeLocationOriginReason doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    return switch (normalized) {
      'outsiderange' => HomeLocationOriginReason.outsideRange,
      'unavailable' => HomeLocationOriginReason.unavailable,
      'live' => HomeLocationOriginReason.live,
      _ => defaultValue,
    };
  }
}
