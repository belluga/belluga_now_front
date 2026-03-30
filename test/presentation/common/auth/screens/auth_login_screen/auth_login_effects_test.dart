import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/widgets/auth_login_effects.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    AuthWallTelemetry.resetForTesting();
  });

  tearDown(() async {
    await GetIt.I.reset();
    AuthWallTelemetry.resetForTesting();
  });

  testWidgets('shows snackbar and clears general error', (tester) async {
    var cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: AuthLoginEffects(
          generalError: 'Erro desconhecido',
          loginResult: null,
          signUpResult: null,
          onClearGeneralError: () => cleared = true,
          onClearLoginResult: () {},
          onClearSignUpResult: () {},
          child: const Scaffold(
            body: Text('Body'),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Erro desconhecido'), findsOneWidget);
    expect(cleared, isTrue);
  });

  testWidgets(
      'signup completion telemetry source is auth_wall when gate was triggered',
      (tester) async {
    final telemetry = _RecordingTelemetryRepository();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);
    final router = _RecordingStackRouter();
    AuthWallTelemetry.trackTriggered(
      actionType: AuthWallActionType.favorite,
      redirectPath: '/descobrir',
    );

    await tester.pumpWidget(
      _buildRoutedHost(
        router: router,
        child: AuthLoginEffects(
          generalError: null,
          loginResult: null,
          signUpResult: true,
          onClearGeneralError: () {},
          onClearLoginResult: () {},
          onClearSignUpResult: () {},
          child: const Scaffold(body: Text('Body')),
        ),
      ),
    );

    await tester.pump();

    final signupEvent = telemetry.loggedEvents.firstWhere(
      (event) => event.eventName == 'app_signup_completed',
    );
    expect(signupEvent.properties?['source'], 'auth_wall');
    expect(signupEvent.properties?['action_type'], 'favorite');
  });

  testWidgets('signup completion telemetry source is direct by default',
      (tester) async {
    final telemetry = _RecordingTelemetryRepository();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);
    final router = _RecordingStackRouter();

    await tester.pumpWidget(
      _buildRoutedHost(
        router: router,
        child: AuthLoginEffects(
          generalError: null,
          loginResult: null,
          signUpResult: true,
          onClearGeneralError: () {},
          onClearLoginResult: () {},
          onClearSignUpResult: () {},
          child: const Scaffold(body: Text('Body')),
        ),
      ),
    );

    await tester.pump();

    final signupEvent = telemetry.loggedEvents.firstWhere(
      (event) => event.eventName == 'app_signup_completed',
    );
    expect(signupEvent.properties?['source'], 'direct');
    expect(signupEvent.properties?['action_type'], isNull);
  });
}

Widget _buildRoutedHost({
  required StackRouter router,
  required Widget child,
}) {
  final routeData = RouteData(
    route: _FakeRouteMatch(fullPath: '/auth/login'),
    router: router,
    stackKey: const ValueKey('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );

  return MaterialApp(
    home: StackRouterScope(
      controller: router,
      stateHash: 0,
      child: RouteDataScope(
        routeData: routeData,
        child: child,
      ),
    ),
  );
}

class _RecordingStackRouter extends Mock implements StackRouter {
  _RecordingStackRouter() : _rootRouter = _RecordingRootStackRouter();

  final RootStackRouter _rootRouter;

  @override
  RootStackRouter get root => _rootRouter;

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return false;
  }

  @override
  Future<bool> pop<T extends Object?>([T? result]) async {
    return false;
  }

  @override
  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    return null;
  }
}

class _RecordingRootStackRouter extends Mock implements RootStackRouter {
  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return false;
  }

  @override
  Future<bool> pop<T extends Object?>([T? result]) async {
    return false;
  }
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.fullPath,
    Map<String, dynamic> queryParams = const {},
  }) : _queryParams = Parameters(queryParams);

  @override
  final String fullPath;

  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;
}

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

class _RecordingTelemetryRepository implements TelemetryRepositoryContract {
  final List<_LoggedEvent> loggedEvents = <_LoggedEvent>[];

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    loggedEvents.add(
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
    return null;
  }

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async {
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
  Future<bool> mergeIdentity({required String previousUserId}) async {
    return true;
  }
}
