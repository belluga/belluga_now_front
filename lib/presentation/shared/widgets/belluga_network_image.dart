import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'belluga_network_image_safe_web_loader_stub.dart'
    if (dart.library.js_interop) 'belluga_network_image_safe_web_loader_web.dart'
    as safe_web;

class BellugaNetworkImage extends StatefulWidget {
  const BellugaNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.color,
    this.colorBlendMode,
    this.filterQuality = FilterQuality.low,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
    this.errorWidget,
    this.clipBorderRadius,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Color? color;
  final BlendMode? colorBlendMode;
  final FilterQuality filterQuality;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  final int? cacheWidth;
  final int? cacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? clipBorderRadius;

  @override
  State<BellugaNetworkImage> createState() => _BellugaNetworkImageState();
}

class _BellugaNetworkImageState extends State<BellugaNetworkImage> {
  bool _retryPending = false;
  bool _hasRetried = false;

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined),
    );
  }

  ImageProvider<Object> _effectiveProvider() {
    final ImageProvider<Object> provider =
        kIsWeb && safe_web.shouldUseBellugaSafeWebImageLoader(widget.url)
        ? _BellugaSafeWebNetworkImageProvider(widget.url)
        : NetworkImage(widget.url);
    return ResizeImage.resizeIfNeeded(
      widget.cacheWidth,
      widget.cacheHeight,
      provider,
    );
  }

  void _scheduleRetry(ImageProvider<Object> provider) {
    if (_hasRetried || _retryPending) {
      return;
    }

    _retryPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await provider.evict();
      if (!mounted) {
        return;
      }

      setState(() {
        _retryPending = false;
        _hasRetried = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = _effectiveProvider();
    Widget image = Image(
      key: ValueKey<bool>(_hasRetried),
      image: provider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      filterQuality: widget.filterQuality,
      semanticLabel: widget.semanticLabel,
      excludeFromSemantics: widget.excludeFromSemantics,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return widget.placeholder ?? _buildPlaceholder(context);
      },
      errorBuilder: (context, error, stackTrace) {
        if (!_hasRetried) {
          _scheduleRetry(provider);
          return widget.placeholder ?? _buildPlaceholder(context);
        }
        return widget.errorWidget ?? _buildPlaceholder(context);
      },
    );

    final borderRadius = widget.clipBorderRadius;
    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius, child: image);
    }

    return image;
  }
}

class _BellugaSafeWebNetworkImageProvider
    extends ImageProvider<_BellugaSafeWebNetworkImageProvider> {
  const _BellugaSafeWebNetworkImageProvider(this.url);

  final String url;

  @override
  Future<_BellugaSafeWebNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<_BellugaSafeWebNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _BellugaSafeWebNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    assert(key == this);
    return MultiFrameImageStreamCompleter(
      codec: _loadAsyncImage(decode),
      scale: 1.0,
      debugLabel: 'BellugaSafeWebNetworkImage("$url")',
    );
  }

  Future<ui.Codec> _loadAsyncImage(ImageDecoderCallback decode) async {
    final bytes = await safe_web.loadBellugaSafeWebImageBytes(url);
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }

    return other is _BellugaSafeWebNetworkImageProvider && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() =>
      '${objectRuntimeType(this, '_BellugaSafeWebNetworkImageProvider')}("$url")';
}
