import 'dart:async';

import 'package:belluga_now/application/router/support/location_permission_blocker.dart';
import 'package:belluga_now/application/router/guards/location_permission_state.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_bool_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class LocationPermissionController implements Disposable {
  static const _postGrantLocationBootstrapTimeout = Duration(seconds: 8);

  LocationPermissionController({
    bool? isWeb,
    LocationPermissionBlockerLoader? initialStateLoader,
    UserLocationRepositoryContract? userLocationRepository,
  }) : this._internal(
         isWeb ?? kIsWeb,
         initialStateLoader ?? loadCurrentLocationPermissionBlocker,
         userLocationRepository,
       );

  LocationPermissionController._internal(
    this._isWeb,
    this._initialStateLoader, [
    this._userLocationRepository,
  ]) : initialStateStreamValue = StreamValue<LocationPermissionState?>(
         defaultValue: null,
       ),
       loading = StreamValue<bool>(defaultValue: false),
       resultStreamValue = StreamValue<bool?>(defaultValue: null);

  final bool _isWeb;
  final LocationPermissionBlockerLoader _initialStateLoader;
  UserLocationRepositoryContract? _userLocationRepository;
  bool _didResolveInitialState = false;

  final StreamValue<LocationPermissionState?> initialStateStreamValue;
  final StreamValue<bool> loading;
  final StreamValue<bool?> resultStreamValue;

  UserLocationRepositoryContract? get _resolvedUserLocationRepository {
    if (_userLocationRepository != null) {
      return _userLocationRepository;
    }
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      return null;
    }
    _userLocationRepository = GetIt.I.get<UserLocationRepositoryContract>();
    return _userLocationRepository;
  }

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
        final currentPermission = await Geolocator.checkPermission();
        if (initialState == LocationPermissionState.deniedForever &&
            currentPermission == LocationPermission.deniedForever) {
          resultStreamValue.addValue(false);
          return;
        }

        final repositoryAvailable = _resolvedUserLocationRepository != null;
        final canonicalLocationResolved =
            await _primeCanonicalLocationAfterPermissionGrant(
              requestPermissionIfNeeded: !_isPermissionGranted(
                currentPermission,
              ),
            );
        if (canonicalLocationResolved) {
          resultStreamValue.addValue(true);
          return;
        }
        if (!repositoryAvailable) {
          resultStreamValue.addValue(false);
          return;
        }

        final permissionAfterBootstrapAttempt =
            await Geolocator.checkPermission();
        resultStreamValue.addValue(
          _isPermissionGranted(permissionAfterBootstrapAttempt),
        );
        return;
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
      if (!granted) {
        resultStreamValue.addValue(false);
        return;
      }

      final canonicalLocationResolved =
          await _primeCanonicalLocationAfterPermissionGrant();
      resultStreamValue.addValue(canonicalLocationResolved);
    } catch (error) {
      debugPrint(
        'LocationPermissionController.requestPermission failed: $error',
      );
      resultStreamValue.addValue(false);
    } finally {
      loading.addValue(false);
    }
  }

  Future<bool> _primeCanonicalLocationAfterPermissionGrant({
    bool requestPermissionIfNeeded = false,
  }) async {
    final repository = _resolvedUserLocationRepository;
    if (repository == null) {
      debugPrint(
        'LocationPermissionController: UserLocationRepositoryContract is not registered.',
      );
      return false;
    }

    await repository.ensureLoaded();
    final resolutionError = await repository.resolveUserLocation(
      requestPermissionIfNeededValue:
          UserLocationRepositoryContractBoolValue.fromRaw(
            requestPermissionIfNeeded,
            defaultValue: requestPermissionIfNeeded,
          ),
      timeout: UserLocationRepositoryContractDurationValue.fromRaw(
        _postGrantLocationBootstrapTimeout,
        defaultValue: _postGrantLocationBootstrapTimeout,
      ),
    );
    return resolutionError == null;
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
