import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_runtime.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/application/router/support/tenant_public_map_entry_flow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  setUp(() {
    resetTenantPublicMapEntryFlowForTesting();
    LocationPermissionGateRuntime.resetForTesting();
  });

  tearDown(() {
    resetTenantPublicMapEntryFlowForTesting();
    LocationPermissionGateRuntime.resetForTesting();
  });

  test('opens map directly when no permission blocker exists', () async {
    final router = _RecordingStackRouter();

    await openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => null,
    );
    await Future<void>.microtask(() {});

    expect(router.pushCalls.length, 1);
    expect(router.pushCalls.single.routeName, CityMapRoute.name);
  });

  test('cancelled warm permission flow does not push map', () async {
    final router = _RecordingStackRouter(
      permissionResult: LocationPermissionGateResult.cancelled,
    );

    await openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );
    await Future<void>.microtask(() {});

    expect(router.pushCalls.length, 1);
    expect(router.pushCalls.single.routeName, LocationPermissionRoute.name);
    expect(
      (router.pushCalls.single as LocationPermissionRoute)
          .args
          ?.popRouteAfterResult,
      isFalse,
    );
    expect(router.maybePopCalls, 1);
    expect(router.replaceCalls, isEmpty);
  });

  test('granted warm permission flow replaces permission with map', () async {
    final router = _RecordingStackRouter(
      permissionResult: LocationPermissionGateResult.granted,
    );

    await openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );
    await Future<void>.microtask(() {});

    expect(router.pushCalls.map((route) => route.routeName).toList(), [
      LocationPermissionRoute.name,
    ]);
    expect(router.replaceCalls.map((route) => route.routeName).toList(), [
      CityMapRoute.name,
    ]);
    expect(router.maybePopCalls, 0);
  });

  test('resolved warm flow clears the in-flight mutex for the next entry', () async {
    final router = _RecordingStackRouter(
      permissionResult: LocationPermissionGateResult.granted,
    );

    await openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );
    await Future<void>.microtask(() {});

    await openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );
    await Future<void>.microtask(() {});

    expect(router.pushCalls.map((route) => route.routeName).toList(), [
      LocationPermissionRoute.name,
      LocationPermissionRoute.name,
    ]);
    expect(router.replaceCalls.map((route) => route.routeName).toList(), [
      CityMapRoute.name,
      CityMapRoute.name,
    ]);
  });

  test(
      'continue without location arms fallback once and replaces permission with map',
      () async {
    final router = _RecordingStackRouter(
      permissionResult: LocationPermissionGateResult.continueWithoutLocation,
    );

    await openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );
    await Future<void>.microtask(() {});

    expect(router.pushCalls.map((route) => route.routeName).toList(), [
      LocationPermissionRoute.name,
    ]);
    expect(router.replaceCalls.map((route) => route.routeName).toList(), [
      CityMapRoute.name,
    ]);
    expect(router.maybePopCalls, 0);
    expect(
      LocationPermissionGateRuntime.consumeSoftLocationFallbackEntry(),
      isTrue,
    );
  });

  test('prevents duplicate permission pushes while the warm flow is in flight',
      () async {
    final completer = Completer<LocationPermissionGateResult?>();
    final router = _RecordingStackRouter(
      permissionFutureFactory: () => completer.future,
    );

    final first = openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );
    final second = openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );

    expect(identical(first, second), isTrue);
    await Future<void>.microtask(() {});
    expect(router.pushCalls.length, 1);
    expect(router.pushCalls.single.routeName, LocationPermissionRoute.name);

    completer.complete(LocationPermissionGateResult.cancelled);
    await first;
  });

  test(
      'granted warm flow resolves the entry mutex even when permission push stays pending after replace',
      () async {
    final router = _RecordingStackRouter(
      permissionResult: LocationPermissionGateResult.granted,
      keepPermissionFuturePendingAfterResult: true,
    );
    addTearDown(() async {
      router.completePendingPermissionPushes();
      await Future<void>.microtask(() {});
    });

    final first = openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );
    await expectLater(
      first.timeout(const Duration(milliseconds: 200)),
      completes,
    );

    final second = openTenantPublicMapEntryFlow(
      router,
      blockerLoader: () async => LocationPermissionState.denied,
    );
    await expectLater(
      second.timeout(const Duration(milliseconds: 200)),
      completes,
    );

    expect(router.pushCalls.map((route) => route.routeName).toList(), [
      LocationPermissionRoute.name,
      LocationPermissionRoute.name,
    ]);
    expect(router.replaceCalls.map((route) => route.routeName).toList(), [
      CityMapRoute.name,
      CityMapRoute.name,
    ]);

    router.completePendingPermissionPushes();
  });

  test('permission push failures propagate and release the entry mutex',
      () async {
    final router = _RecordingStackRouter(
      permissionPushError: StateError('permission push failed'),
    );

    await expectLater(
      openTenantPublicMapEntryFlow(
        router,
        blockerLoader: () async => LocationPermissionState.denied,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'permission push failed',
        ),
      ),
    );

    await expectLater(
      openTenantPublicMapEntryFlow(
        router,
        blockerLoader: () async => LocationPermissionState.denied,
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'permission push failed',
        ),
      ),
    );

    expect(router.pushCalls.map((route) => route.routeName).toList(), [
      LocationPermissionRoute.name,
      LocationPermissionRoute.name,
    ]);
  });
}

class _RecordingStackRouter extends Mock implements RootStackRouter {
  _RecordingStackRouter({
    this.permissionResult,
    this.permissionFutureFactory,
    this.permissionPushError,
    this.keepPermissionFuturePendingAfterResult = false,
  });

  final LocationPermissionGateResult? permissionResult;
  final Future<LocationPermissionGateResult?> Function()?
      permissionFutureFactory;
  final Object? permissionPushError;
  final bool keepPermissionFuturePendingAfterResult;
  final List<PageRouteInfo<dynamic>> pushCalls = <PageRouteInfo<dynamic>>[];
  final List<PageRouteInfo<dynamic>> replaceCalls = <PageRouteInfo<dynamic>>[];
  final List<Completer<LocationPermissionGateResult?>> _pendingPermissionPushes =
      <Completer<LocationPermissionGateResult?>>[];
  int maybePopCalls = 0;

  @override
  RootStackRouter get root => this;

  @override
  Future<T?> push<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    pushCalls.add(route);
    if (route case final LocationPermissionRoute permissionRoute) {
      final pushError = permissionPushError;
      if (pushError != null) {
        throw pushError;
      }
      if (permissionFutureFactory != null) {
        return await permissionFutureFactory!() as T?;
      }
      final result = permissionResult;
      if (result != null) {
        permissionRoute.args?.onResult?.call(result);
        if (keepPermissionFuturePendingAfterResult) {
          final completer = Completer<LocationPermissionGateResult?>();
          _pendingPermissionPushes.add(completer);
          return await completer.future as T?;
        }
      }
    }
    return null;
  }

  @override
  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
  }) async {
    replaceCalls.add(route);
    return null;
  }

  @override
  Future<bool> maybePop<T extends Object?>([T? result]) async {
    maybePopCalls += 1;
    return true;
  }

  void completePendingPermissionPushes() {
    for (final completer in _pendingPermissionPushes) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _pendingPermissionPushes.clear();
  }
}
