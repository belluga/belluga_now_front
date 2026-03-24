import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

typedef AppDataRepositoryContractPrimString = String;
typedef AppDataRepositoryContractPrimInt = int;
typedef AppDataRepositoryContractPrimBool = bool;
typedef AppDataRepositoryContractPrimDouble = double;
typedef AppDataRepositoryContractPrimDateTime = DateTime;
typedef AppDataRepositoryContractPrimDynamic = dynamic;

abstract class AppDataRepositoryContract {
  AppData get appData;

  Future<void> init();

  StreamValue<ThemeMode?> get themeModeStreamValue;
  ThemeMode get themeMode;
  Future<void> setThemeMode(ThemeMode mode);

  StreamValue<AppDataRepositoryContractPrimDouble>
      get maxRadiusMetersStreamValue;
  AppDataRepositoryContractPrimDouble get maxRadiusMeters;
  Future<void> setMaxRadiusMeters(AppDataRepositoryContractPrimDouble meters);
}
