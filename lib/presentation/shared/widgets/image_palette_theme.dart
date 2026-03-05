import 'package:flutter/material.dart';

/// Applies a stable scheme wrapper for image-backed surfaces.
///
/// The widget intentionally avoids asynchronous local state in presentation
/// scope so route/screen composition remains deterministic.
class ImagePaletteTheme extends StatelessWidget {
  const ImagePaletteTheme({
    super.key,
    required this.imageProvider,
    required this.builder,
    this.fallbackScheme,
  });

  final ImageProvider imageProvider;
  final ColorScheme? fallbackScheme;
  final Widget Function(BuildContext context, ColorScheme scheme) builder;

  @override
  Widget build(BuildContext context) {
    final scheme = fallbackScheme ?? Theme.of(context).colorScheme;
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: scheme),
      child: builder(context, scheme),
    );
  }
}
