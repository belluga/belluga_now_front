import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_route_observer.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _LoggedEvent {
  _LoggedEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _TimedEvent {
  _TimedEvent({
    required this.handle,
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerTimedEventHandle handle;
  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  final List<_LoggedEvent> events = <_LoggedEvent>[];
  final List<_TimedEvent> startedEvents = <_TimedEvent>[];
  Map<String, dynamic>? lastScreenContext;
  int _handleSeed = 0;

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    events.add(
      _LoggedEvent(
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
  }) async {
    final handle = EventTrackerTimedEventHandle(
      'handle-${_handleSeed++}',
    );
    startedEvents.add(
      _TimedEvent(
        handle: handle,
        event: event,
        eventName: eventName,
        properties: properties,
      ),
    );
    return handle;
  }

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async {
    final index = startedEvents.indexWhere(
      (entry) => entry.handle.id == handle.id,
    );
    if (index == -1) {
      return true;
    }
    final entry = startedEvents.removeAt(index);
    events.add(
      _LoggedEvent(
        event: entry.event,
        eventName: entry.eventName,
        properties: entry.properties,
      ),
    );
    return true;
  }

  @override
  Future<bool> flushTimedEvents() async {
    return true;
  }

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {
    lastScreenContext = screenContext;
  }

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async {
    return true;
  }
}

void main() {
  testWidgets('tracks screen_view for routes and overlays', (tester) async {
    final telemetryRepository = _FakeTelemetryRepository();
    late BuildContext context;

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [
          TelemetryRouteObserver(telemetryRepository: telemetryRepository),
        ],
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initialCount = telemetryRepository.events.length;
    final initialTimedCount = telemetryRepository.startedEvents.length;

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: RouteSettings(
          name: '/detail',
          arguments: {'event_id': 'evt-1'},
        ),
        builder: (_) => const Scaffold(body: SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    expect(telemetryRepository.events.length, initialCount + 1);
    expect(telemetryRepository.startedEvents.length, initialTimedCount);
    expect(telemetryRepository.lastScreenContext?['route_name'], '/detail');
    expect(telemetryRepository.lastScreenContext?['is_overlay'], false);
    final params =
        telemetryRepository.lastScreenContext?['route_params'] as Map?;
    expect(params?['event_id'], 'evt-1');

    showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(content: Text('Dialog')),
    );
    await tester.pumpAndSettle();

    expect(telemetryRepository.events.length, initialCount + 2);
    expect(telemetryRepository.lastScreenContext?['is_overlay'], true);
    expect(
      telemetryRepository.events.last.properties?['screen_context']
          ?['route_name'],
      '/detail',
    );

    Navigator.of(context).pop();
    await tester.pumpAndSettle();

    expect(telemetryRepository.events.length, initialCount + 3);
    expect(
      telemetryRepository.events.last.properties?['screen_context']
          ?['is_overlay'],
      true,
    );
  });
}
