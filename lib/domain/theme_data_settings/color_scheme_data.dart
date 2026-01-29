import 'package:belluga_now/domain/theme_data_settings/value_objects/brightness_value.dart';
import 'package:belluga_now/domain/value_objects/color_required_value.dart';
import 'package:belluga_now/application/functions/to_hex.dart';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

class ColorSchemeData {
  final ColorRequiredValue primarySeedColorValue;
  final ColorRequiredValue secondarySeedColorValue;
  final BrightnessValue brightnessValue;

  ColorSchemeData({
    required this.brightnessValue,
    required this.primarySeedColorValue,
    required this.secondarySeedColorValue,
  });

  ColorScheme get colorScheme {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primarySeedColorValue.value,
      brightness: brightnessValue.value,
    );

    final hctColor = Hct.fromInt(secondarySeedColorValue.value.toARGB32());
    final secondaryPalette = TonalPalette.fromHct(hctColor);

    if (brightnessValue.value == Brightness.light) {
      return baseScheme.copyWith(
        secondary: Color(secondaryPalette.get(40)),
        onSecondary: Color(secondaryPalette.get(100)),
        secondaryContainer: Color(secondaryPalette.get(90)),
        onSecondaryContainer: Color(secondaryPalette.get(10)),
      );
    } else {
      return baseScheme.copyWith(
        secondary: Color(secondaryPalette.get(80)),
        onSecondary: Color(secondaryPalette.get(20)),
        secondaryContainer: Color(secondaryPalette.get(30)),
        onSecondaryContainer: Color(secondaryPalette.get(90)),
      );
    }
  }

  factory ColorSchemeData.fromJson(Map<String, dynamic> json) {
    final primaryHex = json['primary_seed_color'] as String? ?? '#4FA0E3';
    final secondaryHex = json['secondary_seed_color'] as String? ?? '#E80D5D';

    return ColorSchemeData(
      brightnessValue: BrightnessValue()..parse(json['brightness']),
      primarySeedColorValue:
          ColorRequiredValue(defaultValue: primaryHex.toColor()),
      secondarySeedColorValue:
          ColorRequiredValue(defaultValue: secondaryHex.toColor()),
    );
  }
}
