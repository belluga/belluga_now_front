import 'package:event_tracker_handler/event_tracker_handler.dart';

typedef TelemetryRepositoryContractPrimString = String;
typedef TelemetryRepositoryContractPrimInt = int;
typedef TelemetryRepositoryContractPrimBool = bool;
typedef TelemetryRepositoryContractPrimDouble = double;
typedef TelemetryRepositoryContractPrimDateTime = DateTime;
typedef TelemetryRepositoryContractPrimDynamic = dynamic;

abstract class TelemetryRepositoryContract {
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    Map<TelemetryRepositoryContractPrimString,
            TelemetryRepositoryContractPrimDynamic>?
        properties,
  });

  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    Map<TelemetryRepositoryContractPrimString,
            TelemetryRepositoryContractPrimDynamic>?
        properties,
  });

  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
      EventTrackerTimedEventHandle handle);

  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents();

  void setScreenContext(
      Map<TelemetryRepositoryContractPrimString,
              TelemetryRepositoryContractPrimDynamic>?
          screenContext);

  EventTrackerLifecycleObserver? buildLifecycleObserver();

  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  });
}
