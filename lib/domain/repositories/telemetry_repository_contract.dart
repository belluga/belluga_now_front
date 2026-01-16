import 'package:event_tracker_handler/event_tracker_handler.dart';

abstract class TelemetryRepositoryContract {
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  });

  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  });

  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle);

  Future<bool> flushTimedEvents();

  void setScreenContext(Map<String, dynamic>? screenContext);

  EventTrackerLifecycleObserver? buildLifecycleObserver();

  Future<bool> mergeIdentity({
    required String previousUserId,
  });
}
