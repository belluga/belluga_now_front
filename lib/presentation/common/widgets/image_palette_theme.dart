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
  static final Map<Object, ColorScheme> _cache = {};
  Object? _currentKey;
  ColorScheme? _scheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadScheme();
  }

  Future<void> _loadScheme() async {
    final fallback = widget.fallbackScheme ?? Theme.of(context).colorScheme;
    final key = widget.imageProvider;
    if (key == _currentKey && _scheme != null) {
      return;
    }
    _currentKey = key;
    if (_cache.containsKey(key)) {
      setState(() {
        _scheme = _cache[key];
      });
      return;
    }

    setState(() {
      _scheme = null;
    });
    final scheme = await ColorSchemeGenerator.fromImageProvider(
      widget.imageProvider,
      fallback: fallback,
    );
    if (!mounted || _currentKey != key) {
      return;
    }
    _cache[key] = scheme;
    setState(() {
      _scheme = scheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = _scheme;
    if (scheme == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: scheme),
      child: widget.builder(context, scheme),
    );
  }
}
