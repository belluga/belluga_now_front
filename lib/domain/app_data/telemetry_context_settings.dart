class TelemetryContextSettings {
  const TelemetryContextSettings({
    required this.locationFreshness,
  });

  final Duration locationFreshness;

  static const int defaultLocationFreshnessMinutes = 5;

  static TelemetryContextSettings fromRaw(Object? raw) {
    if (raw is Map) {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);
      final minutes = _parsePositiveInt(
        map['location_freshness_minutes'] ?? map['telemetry_location_freshness_minutes'],
      );
      if (minutes != null) {
        return TelemetryContextSettings(
          locationFreshness: Duration(minutes: minutes),
        );
      }
    }

    return const TelemetryContextSettings(
      locationFreshness: Duration(minutes: defaultLocationFreshnessMinutes),
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
}
