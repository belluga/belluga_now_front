import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:flutter/material.dart';
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

  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.system;

  Future<void> init() async {
    final localInfo = await _localInfoSource.getInfo();

    debugPrint('[AppDataRepository] Fetching branding for host ${localInfo['hostname']}');
    appData = await _fetchRemoteOrFail(localInfo);
    debugPrint('[AppDataRepository] Branding resolved. main_logo_dark=${appData.mainLogoDarkUrl.value} main_icon_dark=${appData.mainIconDarkUrl.value}');
    themeModeStreamValue.addValue(_resolveInitialThemeMode());
    await _precacheLogos();

    if (GetIt.I.isRegistered<AppData>()) {
      GetIt.I.unregister<AppData>();
    }
    GetIt.I.registerSingleton<AppData>(appData);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    // TODO(Delphi): Persist theme preference per user/per device via flutter_secure_storage (and sync backend) once contracts are defined.
    themeModeStreamValue.addValue(mode);
  }

  ThemeMode _resolveInitialThemeMode() =>
      appData.themeDataSettings.brightnessDefault == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light;

  Future<AppData> _fetchRemoteOrFail(Map<String, dynamic> localInfo) async {
    try {
      final dto = await _backend.fetch();
      debugPrint(
        '[AppDataRepository] Using logos -> '
        'main_logo_light: ${dto.mainLogoLightUrl}, main_logo_dark: ${dto.mainLogoDarkUrl}, '
        'main_icon_light: ${dto.mainIconLightUrl}, main_icon_dark: ${dto.mainIconDarkUrl}',
      );
      return AppData.fromDto(dto: dto, localInfo: localInfo);
    } catch (error, stackTrace) {
      debugPrint('AppDataRepository: remote fetch failed. Falling back to origin assets. $error');
      debugPrintStack(stackTrace: stackTrace);
      return _buildLocalFallback(localInfo);
    }
  }

  AppData _buildLocalFallback(Map<String, dynamic> localInfo) {
    final href = localInfo['href'] as String? ?? '';
    final hostname = localInfo['hostname'] as String? ?? 'localhost';
    // Prefer a sane host-based fallback instead of parsing the app name.
    final originCandidate = href.contains('://') ? href : 'https://$hostname';
    final origin = Uri.tryParse(originCandidate)?.origin ?? 'https://localhost';
    final fallbackData = {
      'name': 'Offline',
      'type': 'tenant',
      'main_domain': origin.isNotEmpty ? origin : 'https://localhost',
      'domains': <String>[],
      'app_domains': <String>[],
      'theme_data_settings': {
        'brightness_default': 'light',
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
      },
      'main_color': '#4FA0E3',
      // asset URLs are derived inside AppData from local origin; payload values ignored
      'main_logo_light_url': '$origin/logo-light.png',
      'main_logo_dark_url': '$origin/logo-dark.png',
      'main_icon_light_url': '$origin/icon-light.png',
      'main_icon_dark_url': '$origin/icon-dark.png',
    };
    return AppData.fromInitialization(
      remoteData: fallbackData,
      localInfo: localInfo,
    );
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
}
