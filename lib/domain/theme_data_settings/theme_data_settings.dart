import 'package:belluga_now/domain/theme_data_settings/color_scheme_data.dart';
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

  ThemeData themeData() {
    final schemeData = switch (brightnessDefault) {
      Brightness.dark => darkSchemeData,
      Brightness.light => lightSchemeData,
    };
    return _buildThemeData(schemeData);
  }

  ThemeData themeDataLight() {
    return _buildThemeData(lightSchemeData);
  }

  ThemeData themeDataDark() {
    return _buildThemeData(darkSchemeData);
  }

  ThemeData _buildThemeData(ColorSchemeData schemeData) {
    final colorScheme = schemeData.colorScheme;
    final base = Typography.material2021();
    final themedBase =
        colorScheme.brightness == Brightness.dark ? base.white : base.black;
    final TextTheme textTheme = themedBase.apply(
      displayColor: colorScheme.onSurface,
      bodyColor: colorScheme.onSurfaceVariant,
    );

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
}
