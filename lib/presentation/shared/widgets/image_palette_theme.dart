import 'dart:async';

import 'package:belluga_now/application/extensions/color_scheme_generator.dart';
import 'package:flutter/material.dart';

typedef ImagePaletteThemeSchemeResolver = Future<ColorScheme> Function({
  required ImageProvider imageProvider,
  required ColorScheme fallbackScheme,
});

ThemeData buildImagePaletteThemeData(ThemeData parentTheme, ColorScheme scheme) {
  final textTheme = parentTheme.textTheme.apply(
    displayColor: scheme.onSurface,
    bodyColor: scheme.onSurfaceVariant,
  );

  return parentTheme.copyWith(
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    cardColor: scheme.surface,
    dividerColor: scheme.outlineVariant,
    appBarTheme: parentTheme.appBarTheme.copyWith(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle:
          (parentTheme.appBarTheme.titleTextStyle ?? textTheme.titleLarge)
              ?.copyWith(
        color: scheme.onSurface,
      ),
    ),
    chipTheme: parentTheme.chipTheme.copyWith(
      backgroundColor: scheme.surfaceContainerHighest,
      selectedColor: scheme.secondaryContainer,
      side: BorderSide(color: scheme.outline),
      labelStyle: (parentTheme.chipTheme.labelStyle ?? textTheme.labelLarge)
          ?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),
    progressIndicatorTheme: parentTheme.progressIndicatorTheme.copyWith(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    cardTheme: parentTheme.cardTheme.copyWith(
      color: scheme.surface,
    ),
  );
}

/// Applies a stable scheme wrapper for image-backed surfaces.
///
/// The widget resolves an image-derived [ColorScheme] once and falls back to
/// the ambient theme while extraction is pending or fails.
class ImagePaletteTheme extends StatefulWidget {
  const ImagePaletteTheme({
    super.key,
    required this.imageProvider,
    required this.builder,
    this.fallbackScheme,
    this.schemeResolver,
  });

  final ImageProvider imageProvider;
  final ColorScheme? fallbackScheme;
  final Widget Function(BuildContext context, ColorScheme scheme) builder;
  final ImagePaletteThemeSchemeResolver? schemeResolver;

  @override
  State<ImagePaletteTheme> createState() => _ImagePaletteThemeState();
}

class _ImagePaletteThemeState extends State<ImagePaletteTheme> {
  ColorScheme? _resolvedScheme;
  ColorScheme? _lastFallbackScheme;
  ImageProvider? _lastImageProvider;
  int _resolutionGeneration = 0;
  bool _disposed = false;

  ImagePaletteThemeSchemeResolver get _schemeResolver =>
      widget.schemeResolver ?? _defaultSchemeResolver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureResolvedScheme();
  }

  @override
  void didUpdateWidget(covariant ImagePaletteTheme oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != widget.imageProvider ||
        oldWidget.fallbackScheme != widget.fallbackScheme ||
        oldWidget.schemeResolver != widget.schemeResolver) {
      _ensureResolvedScheme(force: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);
    final scheme =
        _resolvedScheme ?? widget.fallbackScheme ?? parentTheme.colorScheme;
    final themedData = buildImagePaletteThemeData(parentTheme, scheme);
    return Theme(
      data: themedData,
      child: Builder(
        builder: (themedContext) => widget.builder(themedContext, scheme),
      ),
    );
  }

  void _ensureResolvedScheme({bool force = false}) {
    final fallbackScheme =
        widget.fallbackScheme ?? Theme.of(context).colorScheme;
    final shouldResolve = force ||
        _resolvedScheme == null ||
        _lastFallbackScheme != fallbackScheme ||
        _lastImageProvider != widget.imageProvider;

    if (!shouldResolve) {
      return;
    }

    _lastFallbackScheme = fallbackScheme;
    _lastImageProvider = widget.imageProvider;
    _resolvedScheme = fallbackScheme;
    unawaited(_resolveScheme(fallbackScheme));
  }

  Future<void> _resolveScheme(ColorScheme fallbackScheme) async {
    final generation = ++_resolutionGeneration;
    try {
      final derivedScheme = await _schemeResolver(
        imageProvider: widget.imageProvider,
        fallbackScheme: fallbackScheme,
      );
      if (_disposed ||
          generation != _resolutionGeneration ||
          derivedScheme == _resolvedScheme) {
        return;
      }

      setState(() {
        _resolvedScheme = derivedScheme;
      });
    } catch (error) {
      debugPrint('ImagePaletteTheme: fallback due to $error');
    }
  }

  static Future<ColorScheme> _defaultSchemeResolver({
    required ImageProvider imageProvider,
    required ColorScheme fallbackScheme,
  }) {
    return ColorSchemeGenerator.fromImageProvider(
      imageProvider,
      fallback: fallbackScheme,
    );
  }
}
