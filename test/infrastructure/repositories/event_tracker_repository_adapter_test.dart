import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/repositories/event_tracker_repository_adapter.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'delegates package events to the existing telemetry repository',
    () async {
      final telemetry = _FakeTelemetryRepository();
      final adapter = EventTrackerRepositoryAdapter(telemetry);

      final outcomes = await adapter.logEvent(
        type: EventTrackerEvents.videoBegin,
        data: EventTrackerData(
          eventName: 'gallery_youtube_video_begin',
          customData: const {
            'gallery_item_id': 'item-1',
            'youtube_video_id': 'abc123',
          },
        ),
      );

      expect(outcomes, isEmpty);
      expect(telemetry.event, EventTrackerEvents.videoBegin);
      expect(telemetry.eventName, 'gallery_youtube_video_begin');
      expect(telemetry.properties['gallery_item_id'], 'item-1');
      expect(telemetry.properties['youtube_video_id'], 'abc123');
    },
  );
}

final class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  EventTrackerEvents? event;
  String? eventName;
  Map<String, Object?> properties = const {};

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    this.event = event;
    this.eventName = eventName?.value;
    this.properties = TelemetryPropertiesCodec.toRawMap(properties);
    return telemetryRepoBool(true);
  }

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async => telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async => telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async => null;
}
