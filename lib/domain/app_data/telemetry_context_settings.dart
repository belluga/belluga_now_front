import 'package:belluga_now/domain/app_data/value_object/telemetry_location_freshness_value.dart';

class TelemetryContextSettings {
  TelemetryContextSettings({
    required this.locationFreshnessValue,
  });

  final TelemetryLocationFreshnessValue locationFreshnessValue;

  Duration get locationFreshness => locationFreshnessValue.value;

  static const int defaultLocationFreshnessMinutes = 5;
}
