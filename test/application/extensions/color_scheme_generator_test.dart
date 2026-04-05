import 'dart:typed_data';

import 'package:belluga_now/application/extensions/color_scheme_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  testWidgets('derives a non-fallback scheme from a warm memory image',
      (tester) async {
    final fallback = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    final scheme = await tester.runAsync(() {
      return ColorSchemeGenerator.fromImageProvider(
        MemoryImage(_solidPngBytes(const Color(0xFFF4B400))),
        fallback: fallback,
      );
    });

    expect(scheme, isNotNull);
    expect(
      scheme!,
      isA<ColorScheme>(),
    );

    expect(scheme.primary, isNot(equals(fallback.primary)));
    expect(scheme.secondary, isNot(equals(fallback.secondary)));
    expect(scheme.brightness, fallback.brightness);
  });
}

Uint8List _solidPngBytes(Color color) {
  final image = img.Image(width: 8, height: 8);
  image.clear(
    img.ColorRgba8(
      (color.r * 255.0).round().clamp(0, 255),
      (color.g * 255.0).round().clamp(0, 255),
      (color.b * 255.0).round().clamp(0, 255),
      (color.a * 255.0).round().clamp(0, 255),
    ),
  );
  return Uint8List.fromList(img.encodePng(image));
}
