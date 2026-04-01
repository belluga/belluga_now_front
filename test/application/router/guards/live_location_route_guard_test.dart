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
    final guard = LiveLocationRouteGuard(
      blockerLoader: () async => null,
    );
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(fullPath: '/location-sensitive'),
    );

    await guard.onNavigation(resolver, _RecordingStackRouter());

    expect(resolver.nextCalls, [true]);
    expect(resolver.redirectedRoute, isNull);
  });

  test('requires granted result to continue navigation', () async {
    final guard = LiveLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(fullPath: '/location-sensitive'),
    );

    await guard.onNavigation(resolver, _RecordingStackRouter());

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    expect(captured.args?.allowContinueWithoutLocation, isFalse);

    captured.args?.onResult?.call(LocationPermissionGateResult.granted);
    expect(resolver.nextCalls, [true]);
  });

  test('blocks navigation when result is cancelled', () async {
    final guard = LiveLocationRouteGuard(
      blockerLoader: () async => LocationPermissionState.deniedForever,
    );
    final resolver = _RecordingNavigationResolver(
      route: _FakeRouteMatch(fullPath: '/location-sensitive'),
    );

    await guard.onNavigation(resolver, _RecordingStackRouter());

    final captured = resolver.redirectedRoute! as LocationPermissionRoute;
    captured.args?.onResult?.call(LocationPermissionGateResult.cancelled);

    expect(resolver.nextCalls, [false]);
  });
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
