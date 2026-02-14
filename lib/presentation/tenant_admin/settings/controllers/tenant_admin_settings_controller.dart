import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class TenantAdminSettingsController implements Disposable {
  TenantAdminSettingsController({
    AppDataRepositoryContract? appDataRepository,
  }) : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>();

  final AppDataRepositoryContract _appDataRepository;

  AppData get appData => _appDataRepository.appData;
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      _appDataRepository.themeModeStreamValue;
  StreamValue<double> get maxRadiusMetersStreamValue =>
      _appDataRepository.maxRadiusMetersStreamValue;

  Future<void> updateThemeMode(ThemeMode mode) {
    return _appDataRepository.setThemeMode(mode);
  }

  Future<void> updateMaxRadiusMeters(double meters) {
    return _appDataRepository.setMaxRadiusMeters(meters);
  }

  @override
  void onDispose() {}
}
