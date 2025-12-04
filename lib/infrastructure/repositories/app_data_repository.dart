import 'package:belluga_now/application/configurations/app_environment_fallback.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

class AppDataRepository {
  late AppData appData;

  final _backend = GetIt.I.get<AppDataBackendContract>();

  final _localInfoSource = AppDataLocalInfoSource();

  Future<void> init() async {
    final localInfo = await _localInfoSource.getInfo();

    appData = await _fetchRemoteOrFallback(localInfo);
    await _precacheLogos();

    if (GetIt.I.isRegistered<AppData>()) {
      GetIt.I.unregister<AppData>();
    }
    GetIt.I.registerSingleton<AppData>(appData);
  }

  Future<AppData> _fetchRemoteOrFallback(Map<String, dynamic> localInfo) async {
    try {
      final dto = await _backend.fetch();
      return AppData.fromDto(dto: dto, localInfo: localInfo);
    } catch (error, stackTrace) {
      debugPrint(
          'AppDataRepository: remote fetch failed, using fallback. $error');
      debugPrintStack(stackTrace: stackTrace);
      // TODO: Remove fallback in production; this is intended only for local/dev bootstrap.
      final dto = AppDataDTO.fromJson(kLocalEnvironmentFallback);
      return AppData.fromDto(dto: dto, localInfo: localInfo);
    }
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
