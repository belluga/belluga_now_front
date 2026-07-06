import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/boundary_route_dismissal.dart';
import 'package:belluga_now/application/router/support/location_permission_blocker.dart';
import 'package:belluga_now/application/router/support/location_permission_granted_document_reentry.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';

class AnyLocationRouteGuard extends AutoRouteGuard {
  AnyLocationRouteGuard({
    LocationPermissionBlockerLoader? blockerLoader,
    this._documentReentry,
  }) : _blockerLoader = blockerLoader ?? loadCurrentLocationPermissionBlocker;

  final LocationPermissionBlockerLoader _blockerLoader;
  final LocationPermissionGrantedDocumentReentry? _documentReentry;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final pendingRedirectPath = buildRedirectPathFromRouteMatch(resolver.route);
    var didResolveGate = false;
    if (_resolvedGateResult(resolver.route) != null) {
      resolver.next(true);
      return;
    }

    final blocker = await _blockerLoader();
    if (blocker == null) {
      resolver.next(true);
      return;
    }

    resolver.redirectUntil(
      LocationPermissionRoute(
        initialState: blocker,
        allowContinueWithoutLocation: true,
        popRouteAfterResult: true,
        onResult: (result) {
          if (didResolveGate) {
            return;
          }
          didResolveGate = true;

          switch (result) {
            case LocationPermissionGateResult.granted:
              final handledByDocumentReentry =
                  (_documentReentry ??
                  performLocationPermissionGrantedDocumentReentry)(
                    pendingRedirectPath,
                  );
              if (handledByDocumentReentry) {
                resolver.next(false);
                return;
              }
              resolver.overrideNext(
                args: _overrideArgsWithLocationGateResult(
                  resolver.route,
                  LocationPermissionGateResult.granted,
                ),
                reevaluateNext: false,
              );
            case LocationPermissionGateResult.continueWithoutLocation:
              resolver.overrideNext(
                args: _overrideArgsWithLocationGateResult(
                  resolver.route,
                  LocationPermissionGateResult.continueWithoutLocation,
                ),
                reevaluateNext: false,
              );
            case LocationPermissionGateResult.cancelled:
              resolveGuardedBoundaryCancellation(
                resolver: resolver,
                router: router,
                kind: BoundaryDismissKind.locationPermission,
                redirectPath: pendingRedirectPath,
              );
          }
        },
      ),
    );
  }

  LocationPermissionGateResult? _resolvedGateResult(RouteMatch route) {
    final args = route.args;
    return switch (args) {
      final CityMapRouteArgs cityMapArgs => cityMapArgs.locationGateResult,
      final PoiDetailsRouteArgs poiDetailsArgs =>
        poiDetailsArgs.locationGateResult,
      _ => null,
    };
  }

  Object? _overrideArgsWithLocationGateResult(
    RouteMatch route,
    LocationPermissionGateResult result,
  ) {
    final queryPoi = route.queryParams.optString('poi');
    final queryStack = route.queryParams.optString('stack');
    final args = route.args;

    return switch (args) {
      final CityMapRouteArgs cityMapArgs => CityMapRouteArgs(
        key: cityMapArgs.key,
        poi: cityMapArgs.poi ?? queryPoi,
        stack: cityMapArgs.stack ?? queryStack,
        locationGateResult: result,
      ),
      final PoiDetailsRouteArgs poiDetailsArgs => PoiDetailsRouteArgs(
        key: poiDetailsArgs.key,
        poi: poiDetailsArgs.poi ?? queryPoi,
        stack: poiDetailsArgs.stack ?? queryStack,
        locationGateResult: result,
      ),
      _ when route.name == CityMapRoute.name => CityMapRouteArgs(
        poi: queryPoi,
        stack: queryStack,
        locationGateResult: result,
      ),
      _ when route.name == PoiDetailsRoute.name => PoiDetailsRouteArgs(
        poi: queryPoi,
        stack: queryStack,
        locationGateResult: result,
      ),
      _ => null,
    };
  }
}
