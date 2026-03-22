import 'dart:async';

import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class LocationPermissionController implements Disposable {
  LocationPermissionController({
    bool? isWeb,
  })  : _isWeb = isWeb ?? kIsWeb,
        loading = StreamValue<bool>(defaultValue: false),
        resultStreamValue = StreamValue<bool?>(defaultValue: null);

  final bool _isWeb;

  final StreamValue<bool> loading;
  final StreamValue<bool?> resultStreamValue;

  Future<void> requestPermission({
    required LocationPermissionState initialState,
  }) async {
    loading.addValue(true);
    try {
      if (_isWeb) {
        if (initialState == LocationPermissionState.deniedForever) {
          final currentPermission = await Geolocator.checkPermission();
          if (_isPermissionGranted(currentPermission)) {
            resultStreamValue.addValue(true);
            return;
          }
          if (currentPermission == LocationPermission.deniedForever) {
            resultStreamValue.addValue(false);
            return;
          }
        }
        await Geolocator.requestPermission();
      } else {
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
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        resultStreamValue.addValue(false);
        return;
      }

      final permission = await Geolocator.checkPermission();
      final granted = _isPermissionGranted(permission);
      resultStreamValue.addValue(granted);
    } catch (error) {
      debugPrint(
        'LocationPermissionController.requestPermission failed: $error',
      );
      resultStreamValue.addValue(false);
    } finally {
      loading.addValue(false);
    }
  }

  bool _isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
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
