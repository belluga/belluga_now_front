import 'package:event_tracker_handler/event_tracker_handler.dart';

class TelemetrySettings {
  final List<EventTrackerSettingsModel> trackers;

  const TelemetrySettings({
    required this.trackers,
  });

  bool get isEnabled => trackers.isNotEmpty;

  static TelemetrySettings fromRaw(Object? raw) {
    if (raw is Map) {
      final map = raw is Map<String, dynamic>
          ? raw
          : Map<String, dynamic>.from(raw);
      return TelemetrySettings.fromRaw(map['trackers']);
    }

    if (raw is! List) {
      return const TelemetrySettings(trackers: <EventTrackerSettingsModel>[]);
    }

    final settings = <EventTrackerSettingsModel>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        settings.add(EventTrackerSettingsModel.fromMap(item));
      } else if (item is Map) {
        settings.add(
          EventTrackerSettingsModel.fromMap(
            Map<String, dynamic>.from(item),
          ),
        );
      }
    }

    return TelemetrySettings(trackers: List.unmodifiable(settings));
  }
}
