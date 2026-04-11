import 'dart:async';

import 'package:belluga_now/application/router/support/location_permission_blocker.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class LocationPermissionController implements Disposable {
  LocationPermissionController({
    bool? isWeb,
    LocationPermissionBlockerLoader? initialStateLoader,
  })  : _isWeb = isWeb ?? kIsWeb,
        _initialStateLoader =
            initialStateLoader ?? loadCurrentLocationPermissionBlocker,
        initialStateStreamValue =
            StreamValue<LocationPermissionState?>(defaultValue: null),
        loading = StreamValue<bool>(defaultValue: false),
        resultStreamValue = StreamValue<bool?>(defaultValue: null);

  final bool _isWeb;
  final LocationPermissionBlockerLoader _initialStateLoader;
  bool _didResolveInitialState = false;

  final StreamValue<LocationPermissionState?> initialStateStreamValue;
  final StreamValue<bool> loading;
  final StreamValue<bool?> resultStreamValue;

  Future<void> ensureInitialState({
    LocationPermissionState? initialState,
  }) async {
    if (_didResolveInitialState) {
      return;
    }
    _didResolveInitialState = true;

    if (initialState != null) {
      initialStateStreamValue.addValue(initialState);
      return;
    }

    final resolvedState =
        await _initialStateLoader() ?? LocationPermissionState.denied;
    initialStateStreamValue.addValue(resolvedState);
  }

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
    initialStateStreamValue.dispose();
    loading.dispose();
    resultStreamValue.dispose();
  }
}
