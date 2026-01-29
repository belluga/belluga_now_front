import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Utility to derive a ColorScheme from an image.
///
/// Usage:
/// ```dart
/// final scheme = await ColorSchemeGenerator.fromImageProvider(
///   NetworkImage(url),
///   fallback: Theme.of(context).colorScheme,
/// );
/// ```
class ColorSchemeGenerator {
  ColorSchemeGenerator._();

  /// Generates a ColorScheme from the given [ImageProvider].
  /// Returns [fallback] (or a seed on primary blue) when extraction fails.
  static Future<ColorScheme> fromImageProvider(
    ImageProvider provider, {
    ColorScheme? fallback,
  }) async {
    final fallbackScheme =
        fallback ?? ColorScheme.fromSeed(seedColor: Colors.blue);
    final targetBrightness = fallbackScheme.brightness;

    try {
      final ui.Image image = await _loadScaledImage(provider);
      final ByteData? bytes = await image.toByteData();
      if (bytes == null) return fallbackScheme;

      final QuantizerResult quantized = await QuantizerCelebi().quantize(
        bytes.buffer.asUint32List(),
        128,
        returnInputPixelToClusterPixel: true,
      );

      final colorToCount = quantized.colorToCount.map(
        (key, value) => MapEntry<int, int>(_argbFromAbgr(key), value),
      );

      final prominent = Score.score(
        colorToCount,
        desired: 3,
        filter: true,
      );
      if (prominent.isEmpty) return fallbackScheme;

      final primarySeed = prominent[0];
      final secondarySeed =
          prominent.length > 1 ? prominent[1] : prominent[0];

      final primaryHct = Hct.fromInt(primarySeed);
      final secondaryHct = Hct.fromInt(secondarySeed);
      final primaryTones = TonalPalette.of(primaryHct.hue, primaryHct.chroma);
      final secondaryTones =
          TonalPalette.of(secondaryHct.hue, secondaryHct.chroma);

      return ColorScheme.fromSeed(
        seedColor: Color(primaryTones.get(40)),
        brightness: targetBrightness,
      ).copyWith(
        secondary: Color(secondaryTones.get(50)),
        onSecondary: Color(secondaryTones.get(100)),
        secondaryContainer: Color(secondaryTones.get(90)),
      );
    } catch (e) {
      debugPrint('ColorSchemeGenerator: fallback due to $e');
      return fallbackScheme;
    }
  }

  static Future<ui.Image> _loadScaledImage(ImageProvider provider) async {
    const double maxDimension = 112.0;
    final Completer<ui.Image> completer = Completer<ui.Image>();
    late ImageStreamListener listener;
    ui.Image? scaled;

    final ImageStream stream = provider.resolve(
      const ImageConfiguration(size: Size(maxDimension, maxDimension)),
    );

    listener = ImageStreamListener((ImageInfo info, bool sync) async {
      stream.removeListener(listener);
      final image = info.image;
      final width = image.width.toDouble();
      final height = image.height.toDouble();
      final bool needsResize =
          width > maxDimension || height > maxDimension;

      if (!needsResize) {
        scaled = image;
        completer.complete(image);
        return;
      }

      double targetW = width;
      double targetH = height;
      if (width > height) {
        targetW = maxDimension;
        targetH = (maxDimension / width) * height;
      } else {
        targetH = maxDimension;
        targetW = (maxDimension / height) * width;
      }

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, targetW, targetH),
        image: image,
        filterQuality: FilterQuality.low,
      );
      scaled = await recorder.endRecording().toImage(
            targetW.toInt(),
            targetH.toInt(),
          );
      completer.complete(scaled);
    }, onError: (Object exception, StackTrace? stackTrace) {
      stream.removeListener(listener);
      completer.completeError(exception, stackTrace);
    });

    stream.addListener(listener);
    return completer.future;
  }

  static int _argbFromAbgr(int abgr) {
    const int exceptRMask = 0xFF00FFFF;
    const int onlyRMask = ~exceptRMask;
    const int exceptBMask = 0xFFFFFF00;
    const int onlyBMask = ~exceptBMask;
    final int r = (abgr & onlyRMask) >> 16;
    final int b = abgr & onlyBMask;
    return (abgr & exceptRMask & exceptBMask) | (b << 16) | r;
  }
}
