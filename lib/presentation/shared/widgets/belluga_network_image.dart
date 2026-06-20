import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'belluga_network_image_safe_web_loader_stub.dart'
    if (dart.library.js_interop) 'belluga_network_image_safe_web_loader_web.dart'
    as safe_web;

class BellugaNetworkImage extends StatelessWidget {
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

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && safe_web.shouldUseBellugaSafeWebImageLoader(url)) {
      Widget image = Image(
        image: ResizeImage.resizeIfNeeded(
          cacheWidth,
          cacheHeight,
          _BellugaSafeWebNetworkImageProvider(url),
        ),
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        color: color,
        colorBlendMode: colorBlendMode,
        filterQuality: filterQuality,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        gaplessPlayback: true,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder(context);
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildPlaceholder(context);
        },
      );
      return _buildWithImage(context, image);
    }

    Widget image = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      filterQuality: filterQuality,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildPlaceholder(context);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildPlaceholder(context);
      },
    );

    final borderRadius = clipBorderRadius;
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius,
        child: image,
      );
    }

    return image;
  }

  Widget _buildWithImage(BuildContext context, Widget image) {
    final borderRadius = clipBorderRadius;
    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius,
        child: image,
      );
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
