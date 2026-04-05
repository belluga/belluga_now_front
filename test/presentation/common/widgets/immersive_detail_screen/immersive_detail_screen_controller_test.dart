import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
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
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    events.add(
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
  }) async {
    final handle = EventTrackerTimedEventHandle('handle-${_handleSeed++}');
    activeTimedEvents.add(
      _TimedEvent(
        handle: handle,
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return handle;
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
      EventTrackerTimedEventHandle handle) async {
    final index = activeTimedEvents.indexWhere(
      (entry) => entry.handle.id == handle.id,
    );
    if (index == -1) {
      return telemetryRepoBool(true);
    }
    final entry = activeTimedEvents.removeAt(index);
    events.add(
      _LoggedEvent(
        event: entry.event,
        eventName: entry.eventName,
        properties: entry.properties,
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async {
    return telemetryRepoBool(true);
  }

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
          {required TelemetryRepositoryContractPrimString
              previousUserId}) async =>
      telemetryRepoBool(true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('horizontal swipe end moves to adjacent tab and clamps at edges', () {
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
        ImmersiveTabItem(
          title: 'Route',
          content: const SizedBox.shrink(),
        ),
      ],
    );

    expect(controller.currentTabIndexStreamValue.value, 0);

    controller.onHorizontalSwipeEnd(-1000);
    expect(controller.currentTabIndexStreamValue.value, 1);

    controller.onHorizontalSwipeEnd(-1000);
    expect(controller.currentTabIndexStreamValue.value, 2);

    controller.onHorizontalSwipeEnd(-1000);
    expect(controller.currentTabIndexStreamValue.value, 2);

    controller.onHorizontalSwipeEnd(1000);
    expect(controller.currentTabIndexStreamValue.value, 1);

    controller.onHorizontalSwipeEnd(250);
    expect(controller.currentTabIndexStreamValue.value, 1);

    controller.dispose();
  });

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
