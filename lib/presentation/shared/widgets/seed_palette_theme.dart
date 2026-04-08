import 'package:belluga_now/presentation/shared/widgets/image_palette_theme.dart';
import 'package:flutter/material.dart';

class SeedPaletteTheme extends StatelessWidget {
  const SeedPaletteTheme({
    super.key,
    required this.seedColor,
    required this.builder,
    this.fallbackScheme,
  });

  final Color seedColor;
  final ColorScheme? fallbackScheme;
  final Widget Function(BuildContext context, ColorScheme scheme) builder;

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final baseScheme = fallbackScheme ?? parentTheme.colorScheme;
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: baseScheme.brightness,
    );

    return Theme(
      data: buildImagePaletteThemeData(parentTheme, scheme),
      child: Builder(
        builder: (themedContext) => builder(themedContext, scheme),
      ),
    );
  }
}
