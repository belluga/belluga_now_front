import 'package:belluga_now/domain/app_data/value_object/telemetry_location_freshness_value.dart';

class TelemetryContextSettings {
  TelemetryContextSettings({
    required Duration locationFreshness,
  }) : locationFreshnessValue = _buildLocationFreshnessValue(locationFreshness);

  final TelemetryLocationFreshnessValue locationFreshnessValue;

  Duration get locationFreshness => locationFreshnessValue.value;

  static const int defaultLocationFreshnessMinutes = 5;

  static TelemetryContextSettings fromRaw(Object? raw) {
    if (raw is Map) {
      final map =
          raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
      final minutes = _parsePositiveInt(
        map['location_freshness_minutes'] ??
            map['telemetry_location_freshness_minutes'],
      );
      if (minutes != null) {
        return TelemetryContextSettings(
          locationFreshness: Duration(minutes: minutes),
        );
      }
    }

    return TelemetryContextSettings(
      locationFreshness: const Duration(
        minutes: defaultLocationFreshnessMinutes,
      ),
    );
  }

  static int? _parsePositiveInt(Object? raw) {
    if (raw is int) {
      return raw > 0 ? raw : null;
    }
    if (raw is num) {
      final value = raw.toInt();
      return value > 0 ? value : null;
    }
    if (raw is String) {
      final value = int.tryParse(raw.trim());
      return value != null && value > 0 ? value : null;
    }
    return null;
  }

  static TelemetryLocationFreshnessValue _buildLocationFreshnessValue(
    Duration raw,
  ) {
    final value = TelemetryLocationFreshnessValue(
      defaultValue: const Duration(minutes: defaultLocationFreshnessMinutes),
    )..parse(raw.inMinutes.toString());
    return value;
  }
}
