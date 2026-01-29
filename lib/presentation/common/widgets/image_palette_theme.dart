import 'package:belluga_now/application/extensions/color_scheme_generator.dart';
import 'package:flutter/material.dart';

/// Wraps a subtree with a `ColorScheme` derived from an image.
///
/// While the palette is loading, shows a simple progress indicator to avoid
/// flashing the fallback theme before the derived scheme is ready.
class ImagePaletteTheme extends StatefulWidget {
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
  State<ImagePaletteTheme> createState() => _ImagePaletteThemeState();
}

class _ImagePaletteThemeState extends State<ImagePaletteTheme> {
  static final Map<Object, Future<ColorScheme>> _cache = {};
  late final Future<ColorScheme> _schemeFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schemeFuture = _fetchScheme();
  }

  Future<ColorScheme> _fetchScheme() {
    final fallback = widget.fallbackScheme ?? Theme.of(context).colorScheme;
    final key = widget.imageProvider;
    if (_cache.containsKey(key)) return _cache[key]!;
    final future = ColorSchemeGenerator.fromImageProvider(
      widget.imageProvider,
      fallback: fallback,
    );
    _cache[key] = future;
    return future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ColorScheme>(
      future: _schemeFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final scheme = snapshot.data!;
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: scheme),
          child: widget.builder(context, scheme),
        );
      },
    );
  }
}
