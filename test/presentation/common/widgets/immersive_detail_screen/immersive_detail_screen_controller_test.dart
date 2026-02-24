import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/controllers/immersive_detail_screen_controller.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
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
  final List<_TimedEvent> activeTimedEvents = <_TimedEvent>[];
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
    final handle = EventTrackerTimedEventHandle('handle-${_handleSeed++}');
    activeTimedEvents.add(
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
    final index = activeTimedEvents.indexWhere(
      (entry) => entry.handle.id == handle.id,
    );
    if (index == -1) {
      return true;
    }
    final entry = activeTimedEvents.removeAt(index);
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
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

void main() {
  test('logs section_viewed when tab visibility changes', () async {
    final telemetryRepository = _FakeTelemetryRepository();
    final controller = ImmersiveDetailScreenController(
      tabItems: [
        ImmersiveTabItem(
          title: 'Overview',
          content: const SizedBox.shrink(),
        ),
        ImmersiveTabItem(
          title: 'Details',
          content: const SizedBox.shrink(),
        ),
      ],
      initialTabIndex: 1,
      telemetryRepository: telemetryRepository,
    );

    controller.onTabVisibilityChanged(0, 0.3);
    expect(telemetryRepository.events, isEmpty);

    controller.onTabVisibilityChanged(0, 0.4);
    expect(telemetryRepository.events, isEmpty);

    controller.onTabVisibilityChanged(1, 0.6);
    await _flushMicrotasks();
    expect(telemetryRepository.events, hasLength(1));
    expect(telemetryRepository.events.first.eventName, 'section_viewed');
    expect(
      telemetryRepository.events.first.properties?['section_title'],
      'Overview',
    );
    expect(
      telemetryRepository.events.first.properties?['position_index'],
      0,
    );

    controller.dispose();
    await _flushMicrotasks();
    expect(telemetryRepository.events, hasLength(2));
    expect(telemetryRepository.events.last.eventName, 'section_viewed');
    expect(
      telemetryRepository.events.last.properties?['section_title'],
      'Details',
    );
    expect(
      telemetryRepository.events.last.properties?['position_index'],
      1,
    );
  });
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}
