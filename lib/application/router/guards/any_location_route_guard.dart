import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_result.dart';
import 'package:belluga_now/application/router/guards/location_permission_gate_runtime.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

typedef LocationPermissionBlockerLoader = Future<LocationPermissionState?>
    Function();

class AnyLocationRouteGuard extends AutoRouteGuard {
  AnyLocationRouteGuard({
    LocationPermissionBlockerLoader? blockerLoader,
  }) : _blockerLoader = blockerLoader ?? _defaultCurrentBlocker;

  final LocationPermissionBlockerLoader _blockerLoader;

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      resolver.next(true);
      return;
    }

    final locationRepository = GetIt.I.get<UserLocationRepositoryContract>();
    await locationRepository.ensureLoaded();

    final blocker = await _blockerLoader();
    if (blocker == null) {
      resolver.next(true);
      return;
    }

    resolver.redirectUntil(
      LocationPermissionRoute(
        initialState: blocker,
        allowContinueWithoutLocation: true,
        onResult: (result) {
          switch (result) {
            case LocationPermissionGateResult.granted:
              resolver.next(true);
            case LocationPermissionGateResult.continueWithoutLocation:
              LocationPermissionGateRuntime.armSoftLocationFallbackEntry();
              resolver.next(true);
            case LocationPermissionGateResult.cancelled:
              resolver.next(false);
          }
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
