import 'package:belluga_now/domain/app_data/home_location_origin_mode.dart';
import 'package:value_object_pattern/value_object.dart';

class HomeLocationOriginModeValue extends ValueObject<HomeLocationOriginMode> {
  HomeLocationOriginModeValue({
    super.defaultValue = HomeLocationOriginMode.live,
    super.isRequired = false,
  });

  factory HomeLocationOriginModeValue.fromRaw(
    Object? raw, {
    HomeLocationOriginMode defaultValue = HomeLocationOriginMode.live,
    bool isRequired = false,
  }) {
    final value = HomeLocationOriginModeValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is HomeLocationOriginMode) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  HomeLocationOriginMode doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    return switch (normalized) {
      'fixed' => HomeLocationOriginMode.fixed,
      'live' => HomeLocationOriginMode.live,
      _ => defaultValue,
    };
  }
}
