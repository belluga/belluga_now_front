import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/any_location_route_guard.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_bool_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_text_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('allows navigation when blocker is absent', () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter();

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => null,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/mapa'),
    );

    await guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [true]);
    expect(resolver.redirectedRoute, isNull);
  });

  test('allows navigation when map route already carries a granted gate result',
      () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter();

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(
        fullPath: '/mapa',
        args: const CityMapRouteArgs(
          locationGateResult: LocationPermissionGateResult.granted,
        ),
      ),
    );

    await guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [true]);
    expect(resolver.redirectedRoute, isNull);
  });

  test('redirects to location gate and resumes navigation on granted result',
      () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter();

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/mapa'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    final args = captured.args;
    expect(args?.allowContinueWithoutLocation, isTrue);
    expect(args?.initialState, LocationPermissionState.denied);
    expect(args?.popRouteAfterResult, isTrue);

    args?.onResult?.call(LocationPermissionGateResult.granted);

    expect(resolver.nextCalls, isEmpty);
    expect(
      resolver.overrideArgs,
      const CityMapRouteArgs(
        locationGateResult: LocationPermissionGateResult.granted,
      ),
    );
  });

  test(
      'web granted result performs full-document reentry instead of resuming inside the same SPA',
      () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter();
    final reentryPaths = <String>[];

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
      documentReentry: (redirectPath) {
        reentryPaths.add(redirectPath);
        return true;
      },
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/mapa'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    captured.args?.onResult?.call(LocationPermissionGateResult.granted);

    expect(reentryPaths, ['/mapa']);
    expect(resolver.nextCalls, [false]);
    expect(resolver.overrideArgs, isNull);
  });

  test(
      'redirects to location gate and arms soft fallback when continuing without location',
      () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter();

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.serviceDisabled,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(
        fullPath: '/mapa/poi',
        queryParams: const {'poi': 'event:evt-001'},
      ),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    expect(captured.args?.popRouteAfterResult, isTrue);
    captured.args?.onResult
        ?.call(LocationPermissionGateResult.continueWithoutLocation);

    expect(resolver.nextCalls, isEmpty);
    expect(
      resolver.overrideArgs,
      const PoiDetailsRouteArgs(
        poi: 'event:evt-001',
        locationGateResult:
            LocationPermissionGateResult.continueWithoutLocation,
      ),
    );
  });

  test('aborts navigation when gate result is cancelled', () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter();

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.deniedForever,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/mapa'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    expect(captured.args?.popRouteAfterResult, isTrue);
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);

    expect(resolver.nextCalls, [false]);
  });

  test('cancelled gate falls back to home when there is no history', () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter();

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/mapa'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    expect(captured.args?.popRouteAfterResult, isTrue);
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);
    await Future<void>.microtask(() {});

    expect(resolver.nextCalls, [false]);
    expect(router.replaceAllCalls, 1);
    expect(router.lastReplaceAllRoutes?.single.routeName, TenantHomeRoute.name);
  });

  test('cancelled gate preserves existing history without fallback', () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter()..canPopValue = true;

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/mapa'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    expect(captured.args?.popRouteAfterResult, isTrue);
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);
    await Future<void>.microtask(() {});

    expect(resolver.nextCalls, [false]);
    expect(router.replaceAllCalls, 0);
  });

  test('cancelled gate resolution is one-shot', () async {
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    final router = _RecordingStackRouter();

    final guard = AnyLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/mapa'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    expect(captured.args?.popRouteAfterResult, isTrue);
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);
    await Future<void>.microtask(() {});

    expect(resolver.nextCalls, [false]);
    expect(router.replaceAllCalls, 1);
  });
}

class _RecordingNavigationResolver extends NavigationResolver {
  _RecordingNavigationResolver({
    required StackRouter router,
    required RouteMatch route,
  }) : super(
          router,
          Completer<ResolverResult>(),
          route,
        );

  final List<bool> nextCalls = <bool>[];
  PageRouteInfo? redirectedRoute;
  Object? overrideArgs;

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

  @override
  void overrideNext({
    List<PageRouteInfo>? children,
    Object? args,
    Map<String, dynamic>? queryParams,
    String? fragment,
    bool reevaluateNext = true,
  }) {
    overrideArgs = args;
  }
}

class _RecordingStackRouter extends Mock implements StackRouter {
  bool canPopValue = false;
  int replaceAllCalls = 0;
  List<PageRouteInfo>? lastReplaceAllRoutes;

  @override
  RootStackRouter get root => _FakeRootStackRouter();

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    return canPopValue;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo>? routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllCalls += 1;
    lastReplaceAllRoutes = routes;
  }
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  @override
  RootStackRouter get root => this;

  @override
  String get currentPath => '/location/permission';

  @override
  Object? get pathState => null;

  @override
  PageRouteInfo? buildPageRoute(
    String? path, {
    bool includePrefixMatches = true,
  }) {
    final uri = Uri.tryParse(path ?? '');
    if (uri == null) {
      return null;
    }

    return switch (uri.path) {
      '/' => const TenantHomeRoute(),
      '/profile' => const ProfileRoute(),
      _ => null,
    };
  }
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.fullPath,
    Map<String, dynamic> queryParams = const {},
    this.args,
  }) : _queryParams = Parameters(queryParams);

  @override
  final String fullPath;

  @override
  final Object? args;

  @override
  String get name => fullPath.startsWith('/mapa/poi')
      ? PoiDetailsRoute.name
      : CityMapRoute.name;

  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>();

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>();

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>();

  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(
    UserLocationRepositoryContractTextValue? address,
  ) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({
    UserLocationRepositoryContractDurationValue? minInterval,
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation({
    Object? timeout,
    UserLocationRepositoryContractBoolValue? requestPermissionIfNeededValue,
  }) async =>
      null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async {
    return true;
  }

  @override
  Future<void> stopTracking() async {}
}
