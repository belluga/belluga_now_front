import 'package:belluga_now/domain/theme_data_settings/color_scheme_data.dart';
import 'package:belluga_now/domain/theme_data_settings/value_objects/brightness_value.dart';
import 'package:flutter/material.dart';

class ThemeDataSettings {
  final ColorSchemeData lightSchemeData;
  final ColorSchemeData darkSchemeData;
  final Brightness brightnessDefault;

  ThemeDataSettings({
    required this.darkSchemeData,
    required this.lightSchemeData,
    required this.brightnessDefault,
  });

  ThemeData themeData([Brightness? brightness]) {
    final resolvedBrightness = brightness ?? brightnessDefault;
    final ColorScheme colorScheme = switch (resolvedBrightness) {
      Brightness.dark => darkSchemeData.colorScheme,
      Brightness.light => lightSchemeData.colorScheme,
    };

    final TextTheme textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colorScheme.onSecondaryContainer),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        side: BorderSide(color: colorScheme.outline),
        selectedColor: colorScheme.secondaryContainer,
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  factory ThemeDataSettings.fromJson(Map<String, dynamic> json) {
    final brightnessDefaultValue = BrightnessValue()
      ..parse(json['brightness_default']);

    final primarySeedColor = json['primary_seed_color'] as String? ?? '#4FA0E3';
    final secondarySeedColor =
        json['secondary_seed_color'] as String? ?? '#E80D5D';

    final darkSchemeData = ColorSchemeData.fromJson({
      'brightness': 'dark',
      'primary_seed_color': primarySeedColor,
      'secondary_seed_color': secondarySeedColor,
    });

    final lightSchemeData = ColorSchemeData.fromJson({
      'brightness': 'light',
      'primary_seed_color': primarySeedColor,
      'secondary_seed_color': secondarySeedColor,
    });

    return ThemeDataSettings(
      darkSchemeData: darkSchemeData,
      lightSchemeData: lightSchemeData,
      brightnessDefault: brightnessDefaultValue.value == Brightness.dark
          ? Brightness.dark
          : Brightness.light,
    );
  }

  TextTheme _buildTextTheme(ColorScheme colorScheme) {
    final base = Typography.material2021();
    final themedBase =
        colorScheme.brightness == Brightness.dark ? base.white : base.black;
    return themedBase.apply(
      displayColor: colorScheme.onSurface,
      bodyColor: colorScheme.onSurfaceVariant,
    );
  }
}
