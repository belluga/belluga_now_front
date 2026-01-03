import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class AppDataRepository {
  AppDataRepository({
    required AppDataBackendContract backend,
    required AppDataLocalInfoSource localInfoSource,
  })  : _backend = backend,
        _localInfoSource = localInfoSource;

  late AppData appData;

  final AppDataBackendContract _backend;
  final AppDataLocalInfoSource _localInfoSource;
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.system);
  final StreamValue<double> maxRadiusMetersStreamValue =
      StreamValue<double>(defaultValue: 50000);
  static const String _maxRadiusStorageKey = 'max_radius_meters';
  static const String _apiBaseUrlStorageKey = 'api_base_url';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.system;
  double get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  Future<void> init() async {
    final localInfo = await _localInfoSource.getInfo();
    appData = await _fetchRemoteOrFail(localInfo);
    final initialThemeMode = _resolveInitialThemeMode();
    themeModeStreamValue.addValue(initialThemeMode);
    final storedRadius = await _loadMaxRadiusMeters();
    if (storedRadius != null) {
      maxRadiusMetersStreamValue.addValue(storedRadius);
    }
    await _precacheLogos();
    await _persistRuntimeMetadata();

    if (GetIt.I.isRegistered<AppData>()) {
      GetIt.I.unregister<AppData>();
    }
    GetIt.I.registerSingleton<AppData>(appData);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // TODO(Delphi): Persist theme preference per user/per device via flutter_secure_storage (and sync backend) once contracts are defined.
    themeModeStreamValue.addValue(mode);
  }

  Future<void> setMaxRadiusMeters(double meters) async {
    if (meters <= 0) return;
    // TODO(Delphi): Persist radius preference per user/per device via flutter_secure_storage (and sync backend) once contracts are defined.
    maxRadiusMetersStreamValue.addValue(meters);
    await _storage.write(
      key: _maxRadiusStorageKey,
      value: meters.toString(),
    );
  }

  Future<double?> _loadMaxRadiusMeters() async {
    final stored = await _storage.read(key: _maxRadiusStorageKey);
    if (stored == null || stored.trim().isEmpty) return null;
    final parsed = double.tryParse(stored);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  ThemeMode _resolveInitialThemeMode() =>
      appData.themeDataSettings.brightnessDefault == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;

  Future<AppData> _fetchRemoteOrFail(Map<String, dynamic> localInfo) async {
    final dto = await _backend.fetch();
    return AppData.fromDto(dto: dto, localInfo: localInfo);
  }

  Future<void> _precacheLogos() async {
    final urls = <String>{};

    for (final uri in [
      appData.iconUrl.value,
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
    final apiBaseUrl =
        '${appData.schema}://${appData.hostname}/api';
    await _storage.write(
      key: _apiBaseUrlStorageKey,
      value: apiBaseUrl,
    );
  }
}
