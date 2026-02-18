import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crop sheet uses 1:1 and circular ui for avatar', (tester) async {
    final bytes = _createPngBytes(width: 900, height: 1200);
    final file =
        XFile.fromData(bytes, name: 'avatar.png', mimeType: 'image/png');
    final service = _FakeIngestionService(bytes);

    await _pumpWithAutoRoute(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showTenantAdminImageCropSheet(
                    context: context,
                    sourceFile: file,
                    slot: TenantAdminImageSlot.avatar,
                    ingestionService: service,
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Recortar avatar'), findsOneWidget);
    await _pumpUntilFound(tester, find.byType(Crop));

    expect(tester.takeException(), isNull);
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, 1.0);
    expect(crop.withCircleUi, isTrue);
    expect(find.text('Recortar avatar'), findsOneWidget);
    expect(find.text('Usar'), findsOneWidget);
  });

  testWidgets('crop sheet uses 16:9 and non-circular ui for cover',
      (tester) async {
    final bytes = _createPngBytes(width: 1200, height: 1800);
    final file =
        XFile.fromData(bytes, name: 'cover.png', mimeType: 'image/png');
    final service = _FakeIngestionService(bytes);

    await _pumpWithAutoRoute(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  showTenantAdminImageCropSheet(
                    context: context,
                    sourceFile: file,
                    slot: TenantAdminImageSlot.cover,
                    ingestionService: service,
                  );
                },
                child: const Text('open'),
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Recortar capa'), findsOneWidget);
    await _pumpUntilFound(tester, find.byType(Crop));

    expect(tester.takeException(), isNull);
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(crop.aspectRatio, closeTo(16 / 9, 0.0001));
    expect(crop.withCircleUi, isFalse);
    expect(find.text('Recortar capa'), findsOneWidget);
    expect(find.text('Usar'), findsOneWidget);
  });
}

Future<void> _pumpWithAutoRoute(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'crop-sheet-test',
        path: '/',
        builder: (_, __) => child,
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 40,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
  fail('Timed out waiting for widget: $finder');
}

Uint8List _createPngBytes({
  int width = 1600,
  int height = 900,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 45, 180));
  return Uint8List.fromList(img.encodePng(image));
}

class _FakeIngestionService extends TenantAdminImageIngestionService {
  _FakeIngestionService(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> readBytesForCrop(XFile file) async => bytes;
}
