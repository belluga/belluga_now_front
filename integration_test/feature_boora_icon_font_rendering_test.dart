import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders uploaded Boora icon font glyphs on device',
      (tester) async {
    final booraKey = GlobalKey();
    final fallbackKey = GlobalKey();
    final glyphs = <int>[
      BooraIcons.clapperboard.codePoint,
      BooraIcons.local.codePoint,
      BooraIcons.musicalNote.codePoint,
      BooraIcons.invitation.codePoint,
      BooraIcons.invitationOutlined.codePoint,
      BooraIcons.appointment.codePoint,
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _GlyphRow(
                  key: booraKey,
                  glyphs: glyphs,
                  fontFamily: BooraIcons.fontFamily,
                ),
                const SizedBox(height: 16),
                _GlyphRow(
                  key: fallbackKey,
                  glyphs: glyphs,
                  fontFamily: '__missing_boora_icon_font__',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final booraPixels = await _captureRawRgba(booraKey);
    final fallbackPixels = await _captureRawRgba(fallbackKey);

    expect(_inkPixelCount(booraPixels), greaterThan(500));
    expect(_differentPixelCount(booraPixels, fallbackPixels), greaterThan(500));
  });
}

class _GlyphRow extends StatelessWidget {
  const _GlyphRow({
    super.key,
    required this.glyphs,
    required this.fontFamily,
  });

  final List<int> glyphs;
  final String fontFamily;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 320,
        height: 96,
        color: Colors.white,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: glyphs
              .map(
                (codePoint) => Text(
                  String.fromCharCode(codePoint),
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: fontFamily,
                    fontSize: 42,
                    height: 1,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

Future<Uint8List> _captureRawRgba(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 1);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

int _inkPixelCount(Uint8List pixels) {
  var count = 0;
  for (var index = 0; index + 3 < pixels.length; index += 4) {
    final red = pixels[index];
    final green = pixels[index + 1];
    final blue = pixels[index + 2];
    final alpha = pixels[index + 3];
    if (alpha > 0 && (red < 245 || green < 245 || blue < 245)) {
      count += 1;
    }
  }
  return count;
}

int _differentPixelCount(Uint8List left, Uint8List right) {
  final length = left.length < right.length ? left.length : right.length;
  var count = 0;
  for (var index = 0; index + 3 < length; index += 4) {
    final redDelta = (left[index] - right[index]).abs();
    final greenDelta = (left[index + 1] - right[index + 1]).abs();
    final blueDelta = (left[index + 2] - right[index + 2]).abs();
    if (redDelta + greenDelta + blueDelta > 60) {
      count += 1;
    }
  }
  return count;
}
