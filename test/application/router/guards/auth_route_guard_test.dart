import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/telemetry/auth_wall_telemetry.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract_properties.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    AuthWallTelemetry.resetForTesting();
  });

  tearDown(() async {
    await GetIt.I.reset();
    AuthWallTelemetry.resetForTesting();
  });

  test('allows navigation when user is authorized', () {
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(authorized: true),
    );

    final guard = AuthRouteGuard();
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(fullPath: '/convites'),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [true]);
    expect(resolver.redirectedRoute, isNull);
  });

  test('redirects unauthorized user preserving deep-link query params', () {
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(authorized: false),
    );

    final guard = AuthRouteGuard();
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(
        fullPath: '/convites',
        queryParams: const {'code': '31F8RN5QJ9'},
      ),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute!;
    expect(
      captured,
      isA<AuthLoginRoute>(),
    );
    expect(
      captured.rawQueryParams['redirect'],
      '/convites?code=31F8RN5QJ9',
    );
  });

  test('redirects unauthorized web user to promotion route preserving redirect',
      () {
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(authorized: false),
    );

    final guard = AuthRouteGuard(isWebRuntime: true);
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(
        fullPath: '/profile',
        queryParams: const {'tab': 'settings'},
      ),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute!;
    expect(
      captured,
      isA<AppPromotionRoute>(),
    );
    expect(
      captured.rawQueryParams['redirect'],
      '/profile?tab=settings',
    );
  });

  test('normalizes path when route fullPath does not include leading slash',
      () {
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(authorized: false),
    );

    final guard = AuthRouteGuard();
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(
        fullPath: 'convites',
        queryParams: const {'code': 'ABC123'},
      ),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute!;
    expect(
      captured,
      isA<AuthLoginRoute>(),
    );
    expect(
      captured.rawQueryParams['redirect'],
      '/convites?code=ABC123',
    );
  });

  test('tracks auth wall telemetry for send-invite guard interception',
      () async {
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FakeAuthRepository(authorized: false),
    );
    final telemetry = _RecordingTelemetryRepository();
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(telemetry);

    final guard = AuthRouteGuard();
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(
        fullPath: '/convites/compartilhar',
        queryParams: const {'event': 'evt-1'},
      ),
    );
    final router = _RecordingStackRouter();

    guard.onNavigation(resolver, router);
    await Future<void>.delayed(Duration.zero);

    final captured = resolver.redirectedRoute!;
    expect(captured, isA<AuthLoginRoute>());
    expect(
      captured.rawQueryParams['redirect'],
      '/convites/compartilhar?event=evt-1',
    );
    expect(telemetry.loggedEvents, hasLength(1));
    final trackedEvent = telemetry.loggedEvents.first;
    expect(trackedEvent.event, EventTrackerEvents.buttonClick);
    expect(trackedEvent.eventName, 'app_auth_wall_triggered');
    expect(trackedEvent.properties?['action_type'], 'send_invite');
    expect(
      trackedEvent.properties?['redirect_path'],
      '/convites/compartilhar',
    );
  });
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
  Future<TelemetryRepositoryContractBoolValue> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractTextValue? eventName,
    TelemetryRepositoryContractProperties? properties,
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
    return telemetryRepoBool(true, defaultValue: true, isRequired: true);
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractTextValue? eventName,
    TelemetryRepositoryContractProperties? properties,
  }) async {
    return null;
  }

  @override
  Future<TelemetryRepositoryContractBoolValue> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async {
    return telemetryRepoBool(true, defaultValue: true, isRequired: true);
  }

  @override
  Future<TelemetryRepositoryContractBoolValue> flushTimedEvents() async {
    return telemetryRepoBool(true, defaultValue: true, isRequired: true);
  }

  @override
  void setScreenContext(TelemetryRepositoryContractProperties? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractBoolValue> mergeIdentity({
    required TelemetryRepositoryContractTextValue previousUserId,
  }) async {
    return telemetryRepoBool(true, defaultValue: true, isRequired: true);
  }
}

class _RecordingNavigationResolver extends NavigationResolver {
  _RecordingNavigationResolver({
    required RouteMatch route,
  }) : super(
          _RecordingStackRouter(),
          Completer<ResolverResult>(),
          route,
        );

  final List<bool> nextCalls = <bool>[];
  PageRouteInfo? redirectedRoute;

  @override
  void next([bool continueNavigation = true]) {
    nextCalls.add(continueNavigation);
  }

  @override
  void redirectUntil(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool replace = false,
  }) {
    redirectedRoute = route;
  }
}

class _RecordingStackRouter extends Mock implements StackRouter {}

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

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({required this.authorized});

  final bool authorized;

  @override
  Object get backend => Object();

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  String get userToken => authorized ? 'token' : '';

  @override
  bool get isUserLoggedIn => authorized;

  @override
  bool get isAuthorized => authorized;

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => authorized ? 'user-id' : null;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(AuthRepositoryContractParamString newPassword,
      AuthRepositoryContractParamString confirmPassword) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}
