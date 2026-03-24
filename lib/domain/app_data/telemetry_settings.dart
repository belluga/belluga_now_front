import 'package:event_tracker_handler/event_tracker_handler.dart';

class TelemetrySettings {
  final List<EventTrackerSettingsModel> trackers;

  const TelemetrySettings({
    required this.trackers,
  });

  bool get isEnabled => trackers.isNotEmpty;
}
