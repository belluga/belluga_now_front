import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/support/location_permission_blocker.dart';
import 'package:belluga_now/application/router/support/location_permission_granted_document_reentry.dart';
import 'package:flutter/foundation.dart';

Future<void>? _tenantPublicMapEntryFlowInFlight;
const String _tenantPublicMapEntryPath = '/mapa';

Future<void> openTenantPublicMapEntryFlow(
  StackRouter router, {
  LocationPermissionBlockerLoader? blockerLoader,
  LocationPermissionGrantedDocumentReentry? documentReentry,
}) {
  final inFlight = _tenantPublicMapEntryFlowInFlight;
  if (inFlight != null) {
    return inFlight;
  }

  final future = _openTenantPublicMapEntryFlow(
    router.root,
    blockerLoader: blockerLoader,
    documentReentry: documentReentry,
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
  LocationPermissionGrantedDocumentReentry? documentReentry,
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
            final handledByDocumentReentry = (documentReentry ??
                performLocationPermissionGrantedDocumentReentry)(
              _tenantPublicMapEntryPath,
            );
            if (handledByDocumentReentry) {
              completeResolution();
              return;
            }
            unawaited(
              router.replace(
                CityMapRoute(
                  locationGateResult: LocationPermissionGateResult.granted,
                ),
              ),
            );
            completeResolution();
            return;
          case LocationPermissionGateResult.continueWithoutLocation:
            unawaited(
              router.replace(
                CityMapRoute(
                  locationGateResult:
                      LocationPermissionGateResult.continueWithoutLocation,
                ),
              ),
            );
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
  final permissionCompletion = permissionPushFuture.then<void>((_) {
    completeResolution();
  });
  await Future.any<void>(<Future<void>>[
    resolutionCompleter.future,
    permissionCompletion,
  ]);
}
