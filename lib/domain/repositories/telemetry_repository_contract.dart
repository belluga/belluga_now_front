import 'package:event_tracker_handler/event_tracker_handler.dart';

abstract class TelemetryRepositoryContract {
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  });

  Future<bool> mergeIdentity({
    required String previousUserId,
  });
}
