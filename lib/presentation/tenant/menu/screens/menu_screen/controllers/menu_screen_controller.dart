import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:get_it/get_it.dart' show Disposable, GetIt;

class MenuScreenController implements Disposable {
  MenuScreenController({AppDataRepositoryContract? appDataRepository})
      : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>();

  final AppDataRepositoryContract _appDataRepository;

  StreamValue<ThemeMode?> get themeModeStreamValue =>
      _appDataRepository.themeModeStreamValue;
  ThemeMode get themeMode => _appDataRepository.themeMode;

  Future<void> setThemeMode(ThemeMode mode) =>
      _appDataRepository.setThemeMode(mode);

  @override
  void onDispose() {}
}
