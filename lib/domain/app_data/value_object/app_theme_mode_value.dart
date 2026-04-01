import 'package:flutter/material.dart';
import 'package:value_object_pattern/value_object.dart';

class AppThemeModeValue extends ValueObject<ThemeMode> {
  AppThemeModeValue({
    super.defaultValue = ThemeMode.system,
    super.isRequired = false,
  });

  factory AppThemeModeValue.fromRaw(
    Object? raw, {
    ThemeMode defaultValue = ThemeMode.system,
    bool isRequired = false,
  }) {
    final value = AppThemeModeValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is ThemeMode) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  ThemeMode doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    return switch (normalized) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => defaultValue,
    };
  }
}
