import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AppDataRepositoryContract {
  AppData get appData;

  Future<void> init();

  StreamValue<ThemeMode?> get themeModeStreamValue;
  ThemeMode get themeMode;
  Future<void> setThemeMode(ThemeMode mode);

  StreamValue<double> get maxRadiusMetersStreamValue;
  double get maxRadiusMeters;
  Future<void> setMaxRadiusMeters(double meters);
}
