import 'dart:async';

import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class LocationPermissionController implements Disposable {
  LocationPermissionController()
      : loading = StreamValue<bool>(defaultValue: false),
        resultStreamValue = StreamValue<bool?>(defaultValue: null);

  final StreamValue<bool> loading;
  final StreamValue<bool?> resultStreamValue;

  Future<void> requestPermission({
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
      if (!serviceEnabled) {
        resultStreamValue.addValue(false);
        return;
      }

      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      resultStreamValue.addValue(granted);
    } finally {
      loading.addValue(false);
    }
  }

  void clearResult() {
    resultStreamValue.addValue(null);
  }

  @override
  FutureOr<void> onDispose() async {
    loading.dispose();
    resultStreamValue.dispose();
  }
}
