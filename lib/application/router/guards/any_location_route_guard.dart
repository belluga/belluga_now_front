import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

class AnyLocationRouteGuard extends AutoRouteGuard {
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

    final cached = locationRepository.lastKnownLocationStreamValue.value;

    final blocker = await _currentBlocker();
    if (blocker == null) {
      resolver.next(true);
      return;
    }

    if (cached != null) {
      final proceed = await router.push<bool>(
        LocationNotLiveRoute(
          blockerState: blocker,
          addressLabel: locationRepository.lastKnownAddressStreamValue.value,
          capturedAt: locationRepository.lastKnownCapturedAtStreamValue.value,
        ),
      );
      resolver.next(proceed == true);
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

