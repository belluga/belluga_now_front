import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationRouteGuard extends AutoRouteGuard {
  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    final blocker = await _currentBlocker();
    if (blocker == null) {
      resolver.next(true);
      return;
    }

    final granted = await router.push<bool>(
      LocationPermissionRoute(initialState: blocker),
    );
    resolver.next(granted == true);
  }

  Future<LocationPermissionState?> _currentBlocker() async {
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

