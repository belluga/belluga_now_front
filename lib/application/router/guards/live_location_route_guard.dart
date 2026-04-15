import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/support/boundary_route_dismissal.dart';
import 'package:belluga_now/application/router/support/location_permission_blocker.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';

class LiveLocationRouteGuard extends AutoRouteGuard {
  LiveLocationRouteGuard({
    LocationPermissionBlockerLoader? blockerLoader,
  }) : _blockerLoader = blockerLoader ?? loadCurrentLocationPermissionBlocker;

  final LocationPermissionBlockerLoader _blockerLoader;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final pendingRedirectPath = buildRedirectPathFromRouteMatch(resolver.route);
    var didResolveGate = false;
    final blocker = await _blockerLoader();
    if (blocker == null) {
      resolver.next(true);
      return;
    }

    resolver.redirectUntil(
      LocationPermissionRoute(
        initialState: blocker,
        allowContinueWithoutLocation: false,
        popRouteAfterResult: true,
        onResult: (result) {
          if (didResolveGate) {
            return;
          }
          didResolveGate = true;

          if (result == LocationPermissionGateResult.granted) {
            resolver.next(true);
            return;
          }

          resolveGuardedBoundaryCancellation(
            resolver: resolver,
            router: router,
            kind: BoundaryDismissKind.locationPermission,
            redirectPath: pendingRedirectPath,
          );
        },
      ),
    );
  }
}
