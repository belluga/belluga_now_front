import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';

final class EventTrackerRepositoryAdapter
    extends EventTrackerRepositoryContract {
  EventTrackerRepositoryAdapter(this._telemetry);

  final TelemetryRepositoryContract _telemetry;

  @override
  Future<void> init() async {}

  @override
  Future<EventTrackerUserData> getUserData() async =>
      EventTrackerUserData(uuid: 'telemetry-adapter');

  @override
  EventTrackerHandler get handler => throw UnsupportedError(
    'The adapter delegates directly to TelemetryRepositoryContract.',
  );

  @override
  void timeEvent(EventTrackerEvents type, {String? eventName}) {}

  @override
  Future<List<EventTrackerDeliveryOutcome>> logEvent({
    required EventTrackerEvents type,
    EventTrackerUserData? userDataCustom,
    EventTrackerData? data,
  }) async {
    await _telemetry.logEvent(
      type,
      eventName: telemetryRepoString(
        data?.eventName ?? type.name,
        defaultValue: type.name,
      ),
      properties: telemetryRepoMap(data?.toMap()),
    );
    return const <EventTrackerDeliveryOutcome>[];
  }
}
