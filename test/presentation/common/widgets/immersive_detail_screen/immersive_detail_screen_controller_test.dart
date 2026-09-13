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
    EventTrackerTimedEventHandle handle,
  ) async {
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
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async => telemetryRepoBool(true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('horizontal swipe end moves to adjacent tab and clamps at edges', () {
    final controller = ImmersiveDetailScreenController(
      tabItems: [
        ImmersiveTabItem(title: 'Overview', content: const SizedBox.shrink()),
        ImmersiveTabItem(title: 'Details', content: const SizedBox.shrink()),
        ImmersiveTabItem(title: 'Route', content: const SizedBox.shrink()),
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

  test('logs section_viewed when tab boundary changes', () async {
    final telemetryRepository = _FakeTelemetryRepository();
    final controller = ImmersiveDetailScreenController(
      tabItems: [
        ImmersiveTabItem(title: 'Overview', content: const SizedBox.shrink()),
        ImmersiveTabItem(title: 'Details', content: const SizedBox.shrink()),
      ],
      initialTabIndex: 1,
      telemetryRepository: telemetryRepository,
    );

    controller.onTabBoundaryChanged(0);
    controller.onTabBoundaryChanged(0);
    controller.onTabBoundaryChanged(1);
    await _flushMicrotasks();
    expect(telemetryRepository.events, hasLength(1));
    expect(telemetryRepository.events.first.eventName, 'section_viewed');
    expect(
      telemetryRepository.events.first.properties?['section_title'],
      'Overview',
    );
    expect(telemetryRepository.events.first.properties?['position_index'], 0);

    controller.dispose();
    await _flushMicrotasks();
    expect(telemetryRepository.events, hasLength(2));
    expect(telemetryRepository.events.last.eventName, 'section_viewed');
    expect(
      telemetryRepository.events.last.properties?['section_title'],
      'Details',
    );
    expect(telemetryRepository.events.last.properties?['position_index'], 1);
  });

  test(
    'ensureTabActivated activates a tab once without changing selection',
    () {
      var firstActivationCount = 0;
      var secondActivationCount = 0;
      final controller = ImmersiveDetailScreenController(
        tabItems: [
          ImmersiveTabItem(
            title: 'Overview',
            onActivated: () => firstActivationCount += 1,
            content: const SizedBox.shrink(),
          ),
          ImmersiveTabItem(
            title: 'Details',
            onActivated: () => secondActivationCount += 1,
            content: const SizedBox.shrink(),
          ),
        ],
      );

      controller.ensureTabActivated(0);
      controller.ensureTabActivated(1);
      controller.ensureTabActivated(1);

      expect(firstActivationCount, 1);
      expect(secondActivationCount, 1);
      expect(controller.currentTabIndexStreamValue.value, 0);

      controller.dispose();
    },
  );

  testWidgets('latest overlapping tab intent owns programmatic scroll', (
    tester,
  ) async {
    final tabs = <ImmersiveTabItem>[
      ImmersiveTabItem(title: 'First', content: const SizedBox.shrink()),
      ImmersiveTabItem(title: 'Second', content: const SizedBox.shrink()),
      ImmersiveTabItem(title: 'Third', content: const SizedBox.shrink()),
    ];
    final controller = ImmersiveDetailScreenController(tabItems: tabs);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          controller: controller.scrollController,
          slivers: [
            for (final tab in tabs)
              SliverToBoxAdapter(child: SizedBox(key: tab.key, height: 700)),
          ],
        ),
      ),
    );
    controller.scrollController.jumpTo(400);

    controller.onTabTapped(0);
    await tester.pump(const Duration(milliseconds: 100));
    controller.onTabTapped(2);
    await tester.pump();

    controller.onTabBoundaryChanged(1);
    expect(
      controller.currentTabIndexStreamValue.value,
      2,
      reason: 'An older cancelled scroll must not release the latest intent.',
    );
  });

  testWidgets('missing target settles after layout', (tester) async {
    final controller = ImmersiveDetailScreenController(
      tabItems: [
        ImmersiveTabItem(title: 'First', content: const SizedBox.shrink()),
        ImmersiveTabItem(title: 'Missing', content: const SizedBox.shrink()),
      ],
    );

    controller.onTabTapped(1);
    await tester.pump();
    await tester.pump();
    controller.onTabBoundaryChanged(0);
    expect(controller.currentTabIndexStreamValue.value, 0);

    controller.dispose();
  });
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
}
