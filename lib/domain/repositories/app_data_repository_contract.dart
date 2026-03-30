import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/app_theme_mode_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

export 'package:belluga_now/domain/app_data/value_object/app_theme_mode_value.dart';

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
  Future<void> setThemeMode(AppThemeModeValue mode);

  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue;
  DistanceInMetersValue get maxRadiusMeters;
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters);
}
