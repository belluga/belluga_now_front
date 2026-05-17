import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_runtime.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/support/location_permission_blocker.dart';
import 'package:flutter/foundation.dart';

Future<void>? _tenantPublicMapEntryFlowInFlight;

Future<void> openTenantPublicMapEntryFlow(
  StackRouter router, {
  LocationPermissionBlockerLoader? blockerLoader,
}) {
  final inFlight = _tenantPublicMapEntryFlowInFlight;
  if (inFlight != null) {
    return inFlight;
  }

  final future = _openTenantPublicMapEntryFlow(
    router.root,
    blockerLoader: blockerLoader,
  );
  _tenantPublicMapEntryFlowInFlight = future.whenComplete(() {
    _tenantPublicMapEntryFlowInFlight = null;
  });
  return _tenantPublicMapEntryFlowInFlight!;
}

@visibleForTesting
void resetTenantPublicMapEntryFlowForTesting() {
  _tenantPublicMapEntryFlowInFlight = null;
}

Future<void> _openTenantPublicMapEntryFlow(
  StackRouter router, {
  LocationPermissionBlockerLoader? blockerLoader,
}) async {
  final blocker =
      await (blockerLoader ?? loadCurrentLocationPermissionBlocker)();
  if (blocker == null) {
    unawaited(router.push(CityMapRoute()));
    return;
  }

  // When the permission screen resolves into router.replace(CityMapRoute()),
  // AutoRoute can keep the original push future pending. The entry mutex must
  // be released from the permission decision itself so a later home -> map tap
  // can start a new flow.
  final resolutionCompleter = Completer<void>();
  void completeResolution() {
    if (!resolutionCompleter.isCompleted) {
      resolutionCompleter.complete();
    }
  }

  var didResolvePermissionRoute = false;
  final permissionPushFuture = router.push<void>(
    LocationPermissionRoute(
      initialState: blocker,
      allowContinueWithoutLocation: true,
      popRouteAfterResult: false,
      onResult: (result) {
        if (didResolvePermissionRoute) {
          return;
        }
        didResolvePermissionRoute = true;

        switch (result) {
          case LocationPermissionGateResult.granted:
            unawaited(router.replace(CityMapRoute()));
            completeResolution();
            return;
          case LocationPermissionGateResult.continueWithoutLocation:
            LocationPermissionGateRuntime.armSoftLocationFallbackEntry();
            unawaited(router.replace(CityMapRoute()));
            completeResolution();
            return;
          case LocationPermissionGateResult.cancelled:
            unawaited(router.maybePop());
            completeResolution();
            return;
        }
      },
    ),
  );
  unawaited(
    permissionPushFuture
        .catchError((Object _, StackTrace __) {})
        .whenComplete(completeResolution),
  );
  await resolutionCompleter.future;
}
