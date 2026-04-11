import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

typedef LocationPermissionBlockerLoader = Future<LocationPermissionState?>
    Function();

Future<LocationPermissionState?> loadCurrentLocationPermissionBlocker() async {
  if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
    return null;
  }

  final locationRepository = GetIt.I.get<UserLocationRepositoryContract>();
  await locationRepository.ensureLoaded();

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
