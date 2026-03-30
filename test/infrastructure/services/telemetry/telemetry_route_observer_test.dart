import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
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
    final handle = EventTrackerTimedEventHandle(
      'handle-${_handleSeed++}',
    );
    startedEvents.add(
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
    final index = startedEvents.indexWhere(
      (entry) => entry.handle.id == handle.id,
    );
    if (index == -1) {
      return telemetryRepoBool(true);
    }
    final entry = startedEvents.removeAt(index);
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
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {
    lastScreenContext = screenContext == null
        ? null
        : TelemetryPropertiesCodec.toRawMap(screenContext);
  }

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity(
      {required TelemetryRepositoryContractPrimString previousUserId}) async {
    return telemetryRepoBool(true);
  }
}

void main() {
  testWidgets('tracks screen_view for routes and overlays', (tester) async {
    final telemetryRepository = _FakeTelemetryRepository();
    final observer = TelemetryRouteObserver(
      telemetryRepository: telemetryRepository,
    );

    final detailRoute = MaterialPageRoute<void>(
      settings: const RouteSettings(
        name: '/detail',
        arguments: {'event_id': 'evt-1'},
      ),
      builder: (_) => const Scaffold(body: SizedBox.shrink()),
    );
    final overlayRoute = _TestPopupRoute(
      settings: const RouteSettings(name: '/overlay'),
    );

    final homeRoute = MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/home'),
      builder: (_) => const Scaffold(body: SizedBox.shrink()),
    );
    observer.didPush(homeRoute, null);
    await tester.pump();
    await tester.pump();

    final initialCount = telemetryRepository.events.length;
    final initialTimedCount = telemetryRepository.startedEvents.length;

    observer.didPush(detailRoute, null);
    await tester.pump();
    await tester.pump();

    expect(telemetryRepository.events.length, initialCount + 1);
    expect(telemetryRepository.startedEvents.length, initialTimedCount);
    expect(telemetryRepository.lastScreenContext?['route_name'], '/detail');
    expect(telemetryRepository.lastScreenContext?['is_overlay'], false);
    final params =
        telemetryRepository.lastScreenContext?['route_params'] as Map?;
    expect(params?['event_id'], 'evt-1');

    observer.didPush(overlayRoute, detailRoute);
    await tester.pump();
    await tester.pump();

    expect(telemetryRepository.events.length, initialCount + 2);
    expect(telemetryRepository.lastScreenContext?['is_overlay'], true);
    expect(
      telemetryRepository.events.last.properties?['screen_context']
          ?['route_name'],
      '/detail',
    );

    observer.didPop(overlayRoute, detailRoute);
    await tester.pump();
    await tester.pump();

    expect(telemetryRepository.events.length, initialCount + 3);
    expect(
      telemetryRepository.events.last.properties?['screen_context']
          ?['is_overlay'],
      true,
    );
  });
}

class _TestPopupRoute extends PopupRoute<void> {
  _TestPopupRoute({required this.settings});

  @override
  final RouteSettings settings;

  @override
  Color? get barrierColor => Colors.black45;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'overlay';

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return const SizedBox.shrink();
  }
}
