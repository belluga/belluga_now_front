import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/any_location_route_guard.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationRouteGuard extends AutoRouteGuard {
  LiveLocationRouteGuard({
    LocationPermissionBlockerLoader? blockerLoader,
  }) : _blockerLoader = blockerLoader ?? _defaultCurrentBlocker;

  final LocationPermissionBlockerLoader _blockerLoader;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final blocker = await _blockerLoader();
    if (blocker == null) {
      resolver.next(true);
      return;
    }

    resolver.redirectUntil(
      LocationPermissionRoute(
        initialState: blocker,
        allowContinueWithoutLocation: false,
        onResult: (result) {
          resolver.next(result == LocationPermissionGateResult.granted);
        },
      ),
    );
  }

  static Future<LocationPermissionState?> _defaultCurrentBlocker() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionState.serviceDisabled;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      return LocationPermissionState.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionState.deniedForever;
    }
    return null;
  }
}
