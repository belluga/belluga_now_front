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

  var didResolvePermissionRoute = false;
  await router.push<void>(
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
            return;
          case LocationPermissionGateResult.continueWithoutLocation:
            LocationPermissionGateRuntime.armSoftLocationFallbackEntry();
            unawaited(router.replace(CityMapRoute()));
            return;
          case LocationPermissionGateResult.cancelled:
            unawaited(router.maybePop());
            return;
        }
      },
    ),
  );
}
