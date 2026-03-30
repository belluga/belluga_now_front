import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract_properties.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';

typedef TelemetryRepositoryContractPrimString
    = TelemetryRepositoryContractTextValue;
typedef TelemetryRepositoryContractPrimBool
    = TelemetryRepositoryContractBoolValue;
typedef TelemetryRepositoryContractPrimMap
    = TelemetryRepositoryContractProperties;

abstract class TelemetryRepositoryContract {
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  });

  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  });

  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
      EventTrackerTimedEventHandle handle);

  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents();

  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext);

  EventTrackerLifecycleObserver? buildLifecycleObserver();

  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  });
}
