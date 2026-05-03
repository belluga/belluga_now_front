import 'dart:async';

import 'package:belluga_now/domain/app_data/location_origin_resolution_request.dart';
import 'package:belluga_now/domain/app_data/location_origin_reason.dart';
import 'package:belluga_now/domain/app_data/location_origin_resolution.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/services/location_origin_service_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class LocationOriginService implements LocationOriginServiceContract {
  LocationOriginService({
    required AppDataRepositoryContract appDataRepository,
    UserLocationRepositoryContract? userLocationRepository,
  })  : _appDataRepository = appDataRepository,
        _userLocationRepository = userLocationRepository {
    _effectiveOriginStreamValue.addValue(resolveCached());
    _bindCanonicalOriginSources();
  }

  final AppDataRepositoryContract _appDataRepository;
  UserLocationRepositoryContract? _userLocationRepository;
  final StreamValue<LocationOriginResolution?> _effectiveOriginStreamValue =
      StreamValue<LocationOriginResolution?>(defaultValue: null);
  StreamSubscription<LocationOriginSettings?>? _locationOriginSettingsSubscription;
  StreamSubscription<CityCoordinate?>? _userLocationSubscription;
  StreamSubscription<CityCoordinate?>? _lastKnownLocationSubscription;
  StreamSubscription<DateTime?>? _lastKnownCapturedAtSubscription;

  @override
  StreamValue<LocationOriginResolution?> get effectiveOriginStreamValue =>
      _effectiveOriginStreamValue;

  UserLocationRepositoryContract? get _resolvedUserLocationRepository {
    if (_userLocationRepository != null) {
      return _userLocationRepository;
    }
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      return null;
    }
    _userLocationRepository = GetIt.I.get<UserLocationRepositoryContract>();
    _bindUserLocationSources(_userLocationRepository!);
    return _userLocationRepository;
  }

  void _bindCanonicalOriginSources() {
    _locationOriginSettingsSubscription ??=
        _appDataRepository.locationOriginSettingsStreamValue.stream.listen((_) {
      _publishCachedResolution();
    });

    final repository = _userLocationRepository;
    if (repository != null) {
      _bindUserLocationSources(repository);
    }
  }

  void _bindUserLocationSources(UserLocationRepositoryContract repository) {
    _userLocationSubscription ??=
        repository.userLocationStreamValue.stream.listen((_) {
      _publishCachedResolution();
    });
    _lastKnownLocationSubscription ??=
        repository.lastKnownLocationStreamValue.stream.listen((_) {
      _publishCachedResolution();
    });
    _lastKnownCapturedAtSubscription ??=
        repository.lastKnownCapturedAtStreamValue.stream.listen((_) {
      _publishCachedResolution();
    });
  }

  void _publishCachedResolution() {
    final next = resolveCached();
    final current = _effectiveOriginStreamValue.value;
    if (_sameResolution(current, next)) {
      return;
    }
    _effectiveOriginStreamValue.addValue(next);
  }

  bool _sameResolution(
    LocationOriginResolution? left,
    LocationOriginResolution right,
  ) {
    if (left == null) {
      return false;
    }

    final leftSettings = left.settings;
    final rightSettings = right.settings;
    if (!(leftSettings?.sameAs(rightSettings) ?? rightSettings == null)) {
      return false;
    }

    return _sameCoordinate(left.effectiveCoordinate, right.effectiveCoordinate) &&
        _sameCoordinate(left.liveUserCoordinate, right.liveUserCoordinate) &&
        _sameCoordinate(left.tenantDefaultCoordinate, right.tenantDefaultCoordinate) &&
        _sameCoordinate(left.userFixedCoordinate, right.userFixedCoordinate) &&
        left.distanceFromTenantDefaultOriginMeters ==
            right.distanceFromTenantDefaultOriginMeters;
  }

  bool _sameCoordinate(CityCoordinate? left, CityCoordinate? right) {
    if (left == null || right == null) {
      return left == right;
    }
    return left.latitude == right.latitude && left.longitude == right.longitude;
  }

  @override
  LocationOriginResolution resolveCached() {
    return _resolveFromUserCoordinate(
      userCoordinate: _resolveFreshLocationCoordinate(
        _resolvedUserLocationRepository,
      ),
    );
  }

  @override
  Future<LocationOriginResolution> resolve(
    LocationOriginResolutionRequest request,
  ) async {
    if (request.forceTenantDefaultUnavailable) {
      return _resolveForcedTenantDefaultUnavailable();
    }
    final userCoordinate = await _resolveUserCoordinate(
      warmUpIfPossible: request.warmUpIfPossible,
      requestPermissionIfNeeded: request.requestPermissionIfNeeded,
      warmUpTimeout: request.warmUpTimeout,
      permissionTimeout: request.permissionTimeout,
    );
    return _resolveFromUserCoordinate(userCoordinate: userCoordinate);
  }

  @override
  Future<LocationOriginResolution> resolveAndPersist(
    LocationOriginResolutionRequest request,
  ) async {
    final resolution = await resolve(request);
    final settings = resolution.settings;
    final currentSettings = _appDataRepository.locationOriginSettings;
    if (settings != null && !(currentSettings?.sameAs(settings) ?? false)) {
      await _appDataRepository.setLocationOriginSettings(settings);
    }
    _effectiveOriginStreamValue.addValue(resolution);
    return resolution;
  }

  LocationOriginResolution _resolveForcedTenantDefaultUnavailable() {
    final tenantDefaultCoordinate = _appDataRepository.appData.tenantDefaultOrigin;
    if (tenantDefaultCoordinate == null) {
      return const LocationOriginResolution(
        settings: null,
        effectiveCoordinate: null,
        liveUserCoordinate: null,
        tenantDefaultCoordinate: null,
        userFixedCoordinate: null,
        distanceFromTenantDefaultOriginValue: null,
      );
    }
    final settings = LocationOriginSettings.tenantDefaultLocation(
      fixedLocationReference: tenantDefaultCoordinate,
      reason: LocationOriginReason.unavailable,
    );
    return LocationOriginResolution(
      settings: settings,
      effectiveCoordinate: tenantDefaultCoordinate,
      liveUserCoordinate: null,
      tenantDefaultCoordinate: tenantDefaultCoordinate,
      userFixedCoordinate: null,
      distanceFromTenantDefaultOriginValue: null,
    );
  }

  LocationOriginResolution _resolveFromUserCoordinate({
    required CityCoordinate? userCoordinate,
  }) {
    final persistedSettings = _appDataRepository.locationOriginSettings;
    final tenantDefaultCoordinate = _appDataRepository.appData.tenantDefaultOrigin;

    if (persistedSettings?.usesUserFixedLocation == true &&
        persistedSettings?.fixedLocationReference != null) {
      final userFixedCoordinate = persistedSettings!.fixedLocationReference;
      return LocationOriginResolution(
        settings: persistedSettings,
        effectiveCoordinate: userFixedCoordinate,
        liveUserCoordinate: userCoordinate,
        tenantDefaultCoordinate: tenantDefaultCoordinate,
        userFixedCoordinate: userFixedCoordinate,
        distanceFromTenantDefaultOriginValue: _resolveDistanceValue(
          userCoordinate: userCoordinate,
          tenantDefaultCoordinate: tenantDefaultCoordinate,
        ),
      );
    }

    final distanceFromTenantDefaultOriginValue = _resolveDistanceValue(
      userCoordinate: userCoordinate,
      tenantDefaultCoordinate: tenantDefaultCoordinate,
    );

    if (userCoordinate != null && tenantDefaultCoordinate != null) {
      final boundaryMeters = _appDataRepository.appData.mapRadiusMaxMeters;
      if (distanceFromTenantDefaultOriginValue != null &&
          distanceFromTenantDefaultOriginValue.value <= boundaryMeters) {
        final settings = LocationOriginSettings.userLiveLocation();
        return LocationOriginResolution(
          settings: settings,
          effectiveCoordinate: userCoordinate,
          liveUserCoordinate: userCoordinate,
          tenantDefaultCoordinate: tenantDefaultCoordinate,
          userFixedCoordinate: null,
          distanceFromTenantDefaultOriginValue:
              distanceFromTenantDefaultOriginValue,
        );
      }

      final settings = LocationOriginSettings.tenantDefaultLocation(
        fixedLocationReference: tenantDefaultCoordinate,
        reason: LocationOriginReason.outsideRange,
      );
      return LocationOriginResolution(
        settings: settings,
        effectiveCoordinate: tenantDefaultCoordinate,
        liveUserCoordinate: userCoordinate,
        tenantDefaultCoordinate: tenantDefaultCoordinate,
        userFixedCoordinate: null,
        distanceFromTenantDefaultOriginValue:
            distanceFromTenantDefaultOriginValue,
      );
    }

    if (userCoordinate != null) {
      final settings = LocationOriginSettings.userLiveLocation();
      return LocationOriginResolution(
        settings: settings,
        effectiveCoordinate: userCoordinate,
        liveUserCoordinate: userCoordinate,
        tenantDefaultCoordinate: tenantDefaultCoordinate,
        userFixedCoordinate: null,
        distanceFromTenantDefaultOriginValue:
            distanceFromTenantDefaultOriginValue,
      );
    }

    if (tenantDefaultCoordinate != null) {
      final settings = LocationOriginSettings.tenantDefaultLocation(
        fixedLocationReference: tenantDefaultCoordinate,
        reason: LocationOriginReason.unavailable,
      );
      return LocationOriginResolution(
        settings: settings,
        effectiveCoordinate: tenantDefaultCoordinate,
        liveUserCoordinate: null,
        tenantDefaultCoordinate: tenantDefaultCoordinate,
        userFixedCoordinate: null,
        distanceFromTenantDefaultOriginValue: null,
      );
    }

    return const LocationOriginResolution(
      settings: null,
      effectiveCoordinate: null,
      liveUserCoordinate: null,
      tenantDefaultCoordinate: null,
      userFixedCoordinate: null,
      distanceFromTenantDefaultOriginValue: null,
    );
  }

  Future<CityCoordinate?> _resolveUserCoordinate({
    required bool warmUpIfPossible,
    required bool requestPermissionIfNeeded,
    Duration? warmUpTimeout,
    Duration? permissionTimeout,
  }) async {
    final repository = _resolvedUserLocationRepository;
    if (repository == null) {
      return null;
    }

    final preWarmUpCoordinate = _resolveFreshLocationCoordinate(repository);
    if (preWarmUpCoordinate != null) {
      return preWarmUpCoordinate;
    }

    if (warmUpIfPossible) {
      try {
        final future = repository.warmUpIfPermitted();
        if (warmUpTimeout != null) {
          await future.timeout(warmUpTimeout, onTimeout: () => false);
        } else {
          await future;
        }
      } on Object {
        // Best-effort warm-up.
      }
    }

    final warmUpCoordinate = _resolveFreshLocationCoordinate(repository);
    if (warmUpCoordinate != null) {
      return warmUpCoordinate;
    }

    if (requestPermissionIfNeeded) {
      try {
        final future = repository.resolveUserLocation();
        if (permissionTimeout != null) {
          await future.timeout(permissionTimeout, onTimeout: () => null);
        } else {
          await future;
        }
      } on Object {
        // Best-effort permission resolution.
      }
    }

    return _resolveFreshLocationCoordinate(repository);
  }

  CityCoordinate? _resolveFreshLocationCoordinate(
    UserLocationRepositoryContract? repository,
  ) {
    if (repository == null) {
      return null;
    }
    final coordinate = repository.userLocationStreamValue.value ??
        repository.lastKnownLocationStreamValue.value;
    if (coordinate == null) {
      return null;
    }

    final capturedAt = repository.lastKnownCapturedAtStreamValue.value;
    if (capturedAt == null) {
      return coordinate;
    }

    final freshnessWindow =
        _appDataRepository.appData.telemetryContextSettings.locationFreshness;
    if (DateTime.now().difference(capturedAt) > freshnessWindow) {
      return null;
    }

    return coordinate;
  }

  DistanceInMetersValue? _resolveDistanceValue({
    required CityCoordinate? userCoordinate,
    required CityCoordinate? tenantDefaultCoordinate,
  }) {
    if (userCoordinate == null || tenantDefaultCoordinate == null) {
      return null;
    }
    return haversineDistanceMeters(
      coordinateA: userCoordinate,
      coordinateB: tenantDefaultCoordinate,
    );
  }
}
