import 'dart:ui';

import 'package:belluga_now/application/extensions/color_scheme_generator.dart';
import 'package:belluga_now/application/extensions/compute_on_color.dart';
import 'package:flutter/material.dart';

class CarouselCard extends StatefulWidget {
  const CarouselCard({
    super.key,
    required this.imageUri,
    required this.contentOverlay,
    this.overlayMode = CarouselCardOverlayMode.bottom,
    this.overlayAlignment = Alignment.bottomLeft,
  });

  final Uri imageUri;
  final Widget contentOverlay;
  final CarouselCardOverlayMode overlayMode;
  final Alignment overlayAlignment;

  @override
  State<CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<CarouselCard> {
  ColorScheme? _derivedScheme;
  ImageProvider get _provider => NetworkImage(widget.imageUri.toString());
  bool _requested = false;
  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    _scheduleSchemeLoad();
  }

  @override
  void didUpdateWidget(covariant CarouselCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUri != widget.imageUri) {
      _derivedScheme = null;
      _requested = false;
      _loadToken++;
      _scheduleSchemeLoad();
    }
  }

  void _scheduleSchemeLoad() {
    if (_requested) {
      return;
    }
    _requested = true;
    final token = ++_loadToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheme = Theme.of(context).colorScheme;
      // Defer to next microtask to avoid sync blocking the init frame.
      Future.microtask(() => _loadScheme(scheme, token));
    });
  }

  Future<void> _loadScheme(ColorScheme fallback, int token) async {
    final scheme = await ColorSchemeGenerator.fromImageProvider(
      _provider,
      fallback: fallback,
    );
    if (token != _loadToken) return;
    setState(() {
      _derivedScheme = scheme;
    });
  }

  @override
  void dispose() {
    _loadToken++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = _derivedScheme ?? theme.colorScheme;
    final overlayBase =
        Color.lerp(Colors.black, scheme.primary, 0.25) ?? Colors.black;
    final onOverlay = overlayBase.computeIconColor(
      context,
      candidates: [
        scheme.onPrimary,
        scheme.onSecondary,
        scheme.onSurface,
        Colors.white,
        Colors.black,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final targetWidth = MediaQuery.of(context).size.width * 0.8;
        final isFullSize = constraints.maxWidth >= targetWidth * 0.8;
        final height = constraints.maxWidth * 9 / 16;
        final overlayChild = DefaultTextStyle.merge(
          style: TextStyle(color: onOverlay),
          child: IconTheme.merge(
            data: IconThemeData(color: onOverlay),
            child: widget.contentOverlay,
          ),
        );

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: Card(
            elevation: 3,
            clipBehavior: Clip.antiAlias,
            color: scheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Image(
                    image: _provider,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(scheme.primary),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.broken_image,
                        size: 48,
                        color: onOverlay.withValues(alpha: 0.6),
                      );
                    },
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        overlayBase.withValues(alpha: 0.88),
                        overlayBase.withValues(alpha: 0.62),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: widget.overlayMode == CarouselCardOverlayMode.fill ? 0 : null,
                  bottom: widget.overlayMode == CarouselCardOverlayMode.bottom
                      ? 0
                      : (widget.overlayMode == CarouselCardOverlayMode.fill
                          ? 0
                          : null),
                  child: isFullSize
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          switchInCurve: Curves.easeOut,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SizeTransition(
                              sizeFactor: animation,
                              axisAlignment: -1,
                              child: child,
                            ),
                          ),
                          child: ConstrainedBox(
                            key: const ValueKey('details'),
                            constraints: const BoxConstraints(minWidth: 0),
                            child:
                                widget.overlayMode == CarouselCardOverlayMode.fill
                                    ? Align(
                                        alignment: widget.overlayAlignment,
                                        child: overlayChild,
                                      )
                                    : overlayChild,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum CarouselCardOverlayMode {
  bottom,
  fill,
}
