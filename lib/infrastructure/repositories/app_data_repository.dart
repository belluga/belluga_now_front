import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/location_origin_reason.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class AppDataRepository implements AppDataRepositoryContract {
  AppDataRepository({
    AppDataBackendContract? backend,
    BackendContract? backendContract,
    required AppDataLocalInfoSource localInfoSource,
  })  : _backend = backend ??
            (backendContract ?? GetIt.I.get<BackendContract>()).appData,
        _localInfoSource = localInfoSource;

  @override
  late AppData appData;

  final AppDataBackendContract _backend;
  final AppDataLocalInfoSource _localInfoSource;
  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.system);
  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
    defaultValue: DistanceInMetersValue.fromRaw(
      50000,
      defaultValue: 50000,
    ),
  );
  @override
  final StreamValue<LocationOriginSettings?> locationOriginSettingsStreamValue =
      StreamValue<LocationOriginSettings?>(defaultValue: null);
  static const String _maxRadiusStorageKey = 'max_radius_meters';
  // Legacy key names are preserved for local compatibility.
  static const String _locationOriginUsesLiveStorageKey =
      'home_use_live_location';
  static const String _locationOriginReasonStorageKey =
      'home_location_origin_reason';
  static const String _locationOriginFixedReferenceLatStorageKey =
      'home_fixed_location_reference_lat';
  static const String _locationOriginFixedReferenceLngStorageKey =
      'home_fixed_location_reference_lng';
  static const String _apiBaseUrlStorageKey = 'api_base_url';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  bool _hasPersistedMaxRadiusPreference = false;
  bool _hasPersistedLocationOriginPreference = false;

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.system;
  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;
  @override
  LocationOriginSettings? get locationOriginSettings =>
      locationOriginSettingsStreamValue.value;
  @override
  bool get hasPersistedMaxRadiusPreference => _hasPersistedMaxRadiusPreference;
  @override
  bool get hasPersistedLocationOriginPreference =>
      _hasPersistedLocationOriginPreference;

  @override
  Future<void> init() async {
    final localInfo = await _localInfoSource.getInfo();
    final remoteData = await _backend.fetch();
    appData = remoteData.toDomain(localInfo: localInfo);
    final initialThemeMode = _resolveInitialThemeMode();
    themeModeStreamValue.addValue(initialThemeMode);
    maxRadiusMetersStreamValue.addValue(
      DistanceInMetersValue.fromRaw(
        appData.mapRadiusMaxMeters,
        defaultValue: appData.mapRadiusMaxMeters,
      ),
    );
    final storedRadius = await _loadMaxRadiusMeters();
    if (storedRadius != null) {
      final clamped = storedRadius.clamp(
        appData.mapRadiusMinMeters,
        appData.mapRadiusMaxMeters,
      );
      maxRadiusMetersStreamValue.addValue(
        DistanceInMetersValue.fromRaw(
          clamped.toDouble(),
          defaultValue: clamped.toDouble(),
        ),
      );
      _hasPersistedMaxRadiusPreference = true;
    } else {
      _hasPersistedMaxRadiusPreference = false;
    }
    final storedLocationOriginSettings = await _loadLocationOriginSettings();
    if (storedLocationOriginSettings != null) {
      locationOriginSettingsStreamValue
          .addValue(storedLocationOriginSettings);
      _hasPersistedLocationOriginPreference = true;
    } else {
      _hasPersistedLocationOriginPreference = false;
    }
    await _precacheLogos();
    await _persistRuntimeMetadata();

    if (GetIt.I.isRegistered<AppData>()) {
      GetIt.I.unregister<AppData>();
    }
    GetIt.I.registerSingleton<AppData>(appData);
  }

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    // TODO(Delphi): Persist theme preference per user/per device via flutter_secure_storage (and sync backend) once contracts are defined.
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    final normalized = meters.value;
    if (normalized <= 0) return;
    final clamped = normalized.clamp(
      appData.mapRadiusMinMeters,
      appData.mapRadiusMaxMeters,
    );
    // TODO(Delphi): Persist radius preference per user/per device via flutter_secure_storage (and sync backend) once contracts are defined.
    maxRadiusMetersStreamValue.addValue(
      DistanceInMetersValue.fromRaw(
        clamped.toDouble(),
        defaultValue: clamped.toDouble(),
      ),
    );
    _hasPersistedMaxRadiusPreference = true;
    await _storage.write(
      key: _maxRadiusStorageKey,
      value: clamped.toString(),
    );
  }

  @override
  Future<void> setLocationOriginSettings(
    LocationOriginSettings settings,
  ) async {
    final current = locationOriginSettingsStreamValue.value;
    if (current != null && current.sameAs(settings)) {
      return;
    }

    locationOriginSettingsStreamValue.addValue(settings);
    _hasPersistedLocationOriginPreference = true;
    await _storage.write(
      key: _locationOriginUsesLiveStorageKey,
      value: settings.usesUserLiveLocation.toString(),
    );
    await _storage.write(
      key: _locationOriginReasonStorageKey,
      value: settings.reason.name,
    );

    final fixedReference = settings.fixedLocationReference;
    if (fixedReference == null) {
      await _storage.delete(key: _locationOriginFixedReferenceLatStorageKey);
      await _storage.delete(key: _locationOriginFixedReferenceLngStorageKey);
      return;
    }

    await _storage.write(
      key: _locationOriginFixedReferenceLatStorageKey,
      value: fixedReference.latitude.toString(),
    );
    await _storage.write(
      key: _locationOriginFixedReferenceLngStorageKey,
      value: fixedReference.longitude.toString(),
    );
  }

  @override
  Future<void> useUserLiveLocationOrigin() {
    return setLocationOriginSettings(
      LocationOriginSettings.userLiveLocation(),
    );
  }

  @override
  Future<void> useUserFixedLocationOrigin({
    required CityCoordinate fixedLocationReference,
  }) {
    return setLocationOriginSettings(
      LocationOriginSettings.userFixedLocation(
        fixedLocationReference: fixedLocationReference,
      ),
    );
  }

  Future<double?> _loadMaxRadiusMeters() async {
    final stored = await _storage.read(key: _maxRadiusStorageKey);
    if (stored == null || stored.trim().isEmpty) return null;
    final parsed = double.tryParse(stored);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Future<LocationOriginSettings?> _loadLocationOriginSettings() async {
    final rawUseLive = await _storage.read(
      key: _locationOriginUsesLiveStorageKey,
    );
    if (rawUseLive == null || rawUseLive.trim().isEmpty) {
      return null;
    }

    final usesUserLiveLocation = rawUseLive.trim().toLowerCase() == 'true';
    if (usesUserLiveLocation) {
      return LocationOriginSettings.userLiveLocation();
    }

    final rawLat = await _storage.read(
      key: _locationOriginFixedReferenceLatStorageKey,
    );
    final rawLng = await _storage.read(
      key: _locationOriginFixedReferenceLngStorageKey,
    );
    if (rawLat == null || rawLng == null) {
      return null;
    }

    final lat = double.tryParse(rawLat);
    final lng = double.tryParse(rawLng);
    if (lat == null || lng == null) {
      return null;
    }

    final reasonRaw = await _storage.read(
      key: _locationOriginReasonStorageKey,
    );
    final reason = switch (reasonRaw?.trim()) {
      'outsideRange' => LocationOriginReason.outsideRange,
      'unavailable' => LocationOriginReason.unavailable,
      'userPreference' => LocationOriginReason.userPreference,
      _ => LocationOriginReason.unavailable,
    };

    final fixedLocationReference = CityCoordinate(
      latitudeValue: LatitudeValue()..parse(lat.toString()),
      longitudeValue: LongitudeValue()..parse(lng.toString()),
    );

    if (reason == LocationOriginReason.userPreference) {
      return LocationOriginSettings.userFixedLocation(
        fixedLocationReference: fixedLocationReference,
      );
    }

    return LocationOriginSettings.tenantDefaultLocation(
      fixedLocationReference: fixedLocationReference,
      reason: reason,
    );
  }

  ThemeMode _resolveInitialThemeMode() =>
      appData.themeDataSettings.brightnessDefault == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;

  Future<void> _precacheLogos() async {
    final urls = <String>{};

    for (final uri in [
      appData.iconMUrl.value,
      appData.mainIconLightUrl.value,
      appData.mainIconDarkUrl.value,
      appData.mainLogoUrl.value,
      appData.mainLogoLightUrl.value,
      appData.mainLogoDarkUrl.value,
    ]) {
      if (uri != null) {
        final url = uri.toString();
        if (url.isNotEmpty) {
          urls.add(url);
        }
      }
    }

    for (final url in urls) {
      try {
        await _precacheUrl(url);
      } catch (_) {
        // Ignore cache failures; logos will be fetched on demand.
      }
    }
  }

  Future<void> _precacheUrl(String url) {
    final completer = Completer<void>();
    final provider = NetworkImage(url);
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        completer.complete();
        stream.removeListener(listener);
      },
      onError: (error, stackTrace) {
        completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  Future<void> _persistRuntimeMetadata() async {
    final apiBaseUrl = appData.mainDomainValue.value.resolve('/api').toString();
    await _storage.write(
      key: _apiBaseUrlStorageKey,
      value: apiBaseUrl,
    );
  }
}
