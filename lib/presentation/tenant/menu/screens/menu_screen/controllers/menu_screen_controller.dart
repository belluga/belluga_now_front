import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;

class MenuScreenController implements Disposable {
  MenuScreenController({AppDataRepository? appDataRepository})
      : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepository>();

  final AppDataRepository _appDataRepository;

  StreamValue<ThemeMode?> get themeModeStreamValue =>
      _appDataRepository.themeModeStreamValue;
  ThemeMode get themeMode => _appDataRepository.themeMode;

  Future<void> setThemeMode(ThemeMode mode) =>
      _appDataRepository.setThemeMode(mode);

  @override
  void onDispose() {}
}
