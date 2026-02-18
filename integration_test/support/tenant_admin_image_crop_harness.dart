import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

RootStackRouter buildSingleScreenTestRouter(Widget child) {
  return RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'tenant-admin-image-crop-test',
        path: '/',
        builder: (_, __) => child,
      ),
    ],
  );
}

Future<void> pumpWithAutoRoute(WidgetTester tester, Widget child) async {
  final router = buildSingleScreenTestRouter(child);
  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 100),
  int maxPumps = 120,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
  fail('Timed out waiting for widget: $finder');
}

File writeTempPng({
  required String name,
  int width = 1600,
  int height = 900,
}) {
  final dir = Directory.systemTemp.createTempSync('belluga_integration_');
  final file = File('${dir.path}/$name');
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 45, 180));
  file.writeAsBytesSync(img.encodePng(image), flush: true);
  return file;
}

class FakeImagePickerPlatform extends ImagePickerPlatform {
  FakeImagePickerPlatform(this.path);

  final String path;

  @override
  Future<XFile?> getImage({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    return XFile(path, name: 'picked.png', mimeType: 'image/png');
  }
}

Future<void> openDeviceCropFlow({
  required WidgetTester tester,
  required Finder trigger,
  required String expectedTitle,
}) async {
  await tester.ensureVisible(trigger);
  await tester.tap(trigger, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await pumpUntilFound(tester, find.text('Do dispositivo'));
  await tester.tap(find.text('Do dispositivo').last, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await pumpUntilFound(tester, find.text(expectedTitle));
  expect(find.text(expectedTitle), findsOneWidget);
  expect(find.text('Usar'), findsOneWidget);
}

Future<void> openWebCropFlow({
  required WidgetTester tester,
  required Finder trigger,
  required String urlSheetTitle,
  required String url,
  required String expectedCropTitle,
}) async {
  await tester.ensureVisible(trigger);
  await tester.tap(trigger, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await pumpUntilFound(tester, find.text('Da web'));
  await tester.tap(find.text('Da web').last, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await pumpUntilFound(tester, find.text(urlSheetTitle));
  final field = find.byType(TextFormField).last;
  await tester.enterText(field, url);
  await tester.pump();
  await tester.tap(find.text('Salvar').last, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));

  await pumpUntilFound(tester, find.text(expectedCropTitle));
  expect(find.text(expectedCropTitle), findsOneWidget);
  expect(find.text('Usar'), findsOneWidget);
}

void expectCropAspectRatio(WidgetTester tester, double expected) {
  final crop = tester.widget<Crop>(find.byType(Crop));
  expect(crop.aspectRatio, closeTo(expected, 0.0001));
}
