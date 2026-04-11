import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/live_location_route_guard.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  test('allows navigation when blocker is absent', () async {
    final router = _RecordingStackRouter();
    final guard = LiveLocationRouteGuard(
      blockerLoader: () async => null,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/location-sensitive'),
    );

    await guard.onNavigation(resolver, router);

    expect(resolver.nextCalls, [true]);
    expect(resolver.redirectedRoute, isNull);
  });

  test('requires granted result to continue navigation', () async {
    final router = _RecordingStackRouter();
    final guard = LiveLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/location-sensitive'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    expect(captured.args?.allowContinueWithoutLocation, isFalse);

    captured.args?.onResult?.call(LocationPermissionGateResult.granted);
    expect(resolver.nextCalls, [true]);
  });

  test('blocks navigation when result is cancelled', () async {
    final router = _RecordingStackRouter();
    final guard = LiveLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.deniedForever,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/location-sensitive'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);

    expect(resolver.nextCalls, [false]);
  });

  test('cancelled gate falls back to home when there is no history', () async {
    final router = _RecordingStackRouter();
    final guard = LiveLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/location-sensitive'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);
    await Future<void>.microtask(() {});

    expect(resolver.nextCalls, [false]);
    expect(router.replaceAllCalls, 1);
    expect(router.lastReplaceAllRoutes?.single.routeName, TenantHomeRoute.name);
  });

  test('cancelled gate preserves existing history without fallback', () async {
    final router = _RecordingStackRouter()..canPopValue = true;
    final guard = LiveLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      router: router,
      route: _FakeRouteMatch(fullPath: '/location-sensitive'),
    );

    await guard.onNavigation(resolver, router);

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);
    await Future<void>.microtask(() {});

    expect(resolver.nextCalls, [false]);
    expect(router.replaceAllCalls, 0);
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
  }) : _queryParams = Parameters(queryParams);

  @override
  final String fullPath;

  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;
}
