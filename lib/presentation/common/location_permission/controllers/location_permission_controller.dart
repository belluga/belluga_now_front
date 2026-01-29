import 'dart:async';

import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class LocationPermissionController implements Disposable {
  LocationPermissionController()
      : loading = StreamValue<bool>(defaultValue: false);

  final StreamValue<bool> loading;

  Future<bool> ensureReady({
    required LocationPermissionState initialState,
  }) async {
    loading.addValue(true);
    try {
      switch (initialState) {
        case LocationPermissionState.serviceDisabled:
          await Geolocator.openLocationSettings();
          break;
        case LocationPermissionState.denied:
          await Geolocator.requestPermission();
          break;
        case LocationPermissionState.deniedForever:
          await Geolocator.openAppSettings();
          break;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } finally {
      loading.addValue(false);
    }
  }

  @override
  FutureOr<void> onDispose() async {
    loading.dispose();
  }
}
