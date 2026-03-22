import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/push/push_telemetry_forwarder.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:push_handler/push_handler.dart';

class _TelemetryCall {
  _TelemetryCall({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _SpyTelemetryRepository implements TelemetryRepositoryContract {
  final List<_TelemetryCall> calls = <_TelemetryCall>[];

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    calls.add(
      _TelemetryCall(
        event: event,
        eventName: eventName,
        properties: properties,
      ),
    );
    return true;
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async =>
      null;

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async =>
      true;

  @override
  Future<bool> flushTimedEvents() async => true;

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

void main() {
  test('forward maps button_tap and forwards payload with idempotency key',
      () async {
    final telemetry = _SpyTelemetryRepository();
    final forwarder = PushTelemetryForwarder(telemetryRepository: telemetry);
    final timestamp = DateTime.utc(2026, 3, 22, 12, 30, 0);

    await forwarder.forward(
      PushEvent(
        type: 'button_tap',
        pushId: 'push-1',
        messageInstanceId: 'msg-1',
        stepSlug: 'invite-step',
        stepType: 'cta',
        buttonKey: 'accept',
        actionType: 'open',
        routeKey: 'invite/detail',
        appState: 'foreground',
        source: 'fcm',
        timestamp: timestamp,
        metadata: const {
          'campaign': 'fall-release',
          'priority': 'high',
        },
      ),
    );

    expect(telemetry.calls, hasLength(1));
    final call = telemetry.calls.single;
    expect(call.event, EventTrackerEvents.buttonClick);
    expect(call.eventName, 'push_button_tap');
    expect(call.properties?['push_id'], 'push-1');
    expect(call.properties?['message_instance_id'], 'msg-1');
    expect(call.properties?['step_slug'], 'invite-step');
    expect(call.properties?['step_type'], 'cta');
    expect(call.properties?['button_key'], 'accept');
    expect(call.properties?['action_type'], 'open');
    expect(call.properties?['route_key'], 'invite/detail');
    expect(call.properties?['app_state'], 'foreground');
    expect(call.properties?['source'], 'fcm');
    expect(call.properties?['timestamp'], timestamp.toIso8601String());
    expect(call.properties?['campaign'], 'fall-release');
    expect(call.properties?['priority'], 'high');
    expect(
      call.properties?['idempotency_key'],
      'push:button_tap:push-1:msg-1:invite-step:accept',
    );
  });

  test('forward maps submit events to selectItem', () async {
    final telemetry = _SpyTelemetryRepository();
    final forwarder = PushTelemetryForwarder(telemetryRepository: telemetry);

    await forwarder.forward(
      PushEvent(
        type: 'submit',
        pushId: 'push-2',
        appState: 'background',
        source: 'local',
        timestamp: DateTime.utc(2026, 3, 22, 13, 0, 0),
      ),
    );

    expect(telemetry.calls, hasLength(1));
    final call = telemetry.calls.single;
    expect(call.event, EventTrackerEvents.selectItem);
    expect(call.eventName, 'push_submit');
    expect(call.properties?['idempotency_key'], 'push:submit:push-2:::');
  });

  test('forward maps unknown types to viewContent', () async {
    final telemetry = _SpyTelemetryRepository();
    final forwarder = PushTelemetryForwarder(telemetryRepository: telemetry);

    await forwarder.forward(
      PushEvent(
        type: 'opened',
        pushId: 'push-3',
        appState: 'foreground',
        source: 'fcm',
        timestamp: DateTime.utc(2026, 3, 22, 14, 0, 0),
      ),
    );

    expect(telemetry.calls, hasLength(1));
    final call = telemetry.calls.single;
    expect(call.event, EventTrackerEvents.viewContent);
    expect(call.eventName, 'push_opened');
    expect(call.properties?['idempotency_key'], 'push:opened:push-3:::');
  });
}
