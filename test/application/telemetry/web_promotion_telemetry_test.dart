import 'package:belluga_now/application/telemetry/web_promotion_telemetry.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('open app click emits open and install funnel events', () async {
    final telemetry = _RecordingTelemetryRepository();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);

    await WebPromotionTelemetry.trackOpenAppClick(platformTarget: 'android');

    expect(
      telemetry.loggedEvents.map((event) => event.eventName).toList(),
      ['web_open_app_clicked', 'web_install_clicked'],
    );
    for (final event in telemetry.loggedEvents) {
      expect(event.event, EventTrackerEvents.buttonClick);
      expect(event.properties?['store_channel'], 'web');
      expect(event.properties?['platform_target'], 'android');
    }
  });
}

class _LoggedEvent {
  const _LoggedEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _RecordingTelemetryRepository implements TelemetryRepositoryContract {
  final List<_LoggedEvent> loggedEvents = <_LoggedEvent>[];

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    loggedEvents.add(
      _LoggedEvent(
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      null;

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async =>
      telemetryRepoBool(true);
}
