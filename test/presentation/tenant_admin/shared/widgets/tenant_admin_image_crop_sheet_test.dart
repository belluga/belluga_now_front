import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_public_web_image_spec.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/widgets/tenant_admin_image_crop_sheet.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

const _heroCropCompositionGuideKey =
    ValueKey<String>('tenantAdminHeroCropCompositionGuide');
const _heroCropTopInterfaceZoneKey =
    ValueKey<String>('tenantAdminHeroCropTopInterfaceZone');
const _heroCropBottomInterfaceZoneKey =
    ValueKey<String>('tenantAdminHeroCropBottomInterfaceZone');
const _heroCropLeftBreathingZoneKey =
    ValueKey<String>('tenantAdminHeroCropLeftBreathingZone');
const _heroCropRightBreathingZoneKey =
    ValueKey<String>('tenantAdminHeroCropRightBreathingZone');
const _heroCropFocusZoneKey = ValueKey<String>('tenantAdminHeroCropFocusZone');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const expectedLegacyCoverAspectRatio = 560 / 512;
  const expectedEventHeroCoverAspectRatio = 5 / 7;
  const expectedAccountProfileHeroCoverAspectRatio = 15 / 16;

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
                    readBytesForCrop: service.readBytesForCrop,
                    prepareCroppedFile: (croppedData, slot) =>
                        service.prepareBytesAsXFile(
                      croppedData,
                      slot: slot,
                      applyAspectCrop: false,
                    ),
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

  testWidgets('crop sheet uses 560:512 and non-circular ui for cover',
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
                    readBytesForCrop: service.readBytesForCrop,
                    prepareCroppedFile: (croppedData, slot) =>
                        service.prepareBytesAsXFile(
                      croppedData,
                      slot: slot,
                      applyAspectCrop: false,
                    ),
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
    expect(crop.aspectRatio, closeTo(expectedLegacyCoverAspectRatio, 0.0001));
    expect(crop.withCircleUi, isFalse);
    expect(find.text('Recortar capa'), findsOneWidget);
    expect(find.text('Área segura do hero'), findsNothing);
    expect(find.byKey(_heroCropCompositionGuideKey), findsNothing);
    expect(find.text('Usar'), findsOneWidget);
  });

  testWidgets('crop sheet uses 5:7 hero preset and safe guide for events',
      (tester) async {
    final crop = await _openCropSheetForSlot(
      tester,
      const _CropSheetRatioCase(
        slot: TenantAdminImageSlot.eventHeroCover,
        expectedTitle: 'Recortar capa do evento',
        expectedAspectRatio: expectedEventHeroCoverAspectRatio,
      ),
    );

    expect(
        crop.aspectRatio, closeTo(expectedEventHeroCoverAspectRatio, 0.0001));
    expect(crop.withCircleUi, isFalse);
    expect(crop.overlayBuilder, isNotNull);
    await _expectHeroCropCompositionGuide(
      tester,
      expectedAspectRatio: expectedEventHeroCoverAspectRatio,
      bottomLabel: 'Texto e botoes',
      helper: 'Preencha o recorte mantendo o assunto principal no centro.',
    );
    expect(find.text('Área segura do hero'), findsNothing);
  });

  testWidgets(
      'crop sheet uses 15:16 hero preset and safe guide for account profiles',
      (tester) async {
    final crop = await _openCropSheetForSlot(
      tester,
      const _CropSheetRatioCase(
        slot: TenantAdminImageSlot.accountProfileHeroCover,
        expectedTitle: 'Recortar capa do perfil',
        expectedAspectRatio: expectedAccountProfileHeroCoverAspectRatio,
      ),
    );

    expect(
      crop.aspectRatio,
      closeTo(expectedAccountProfileHeroCoverAspectRatio, 0.0001),
    );
    expect(crop.withCircleUi, isFalse);
    expect(crop.overlayBuilder, isNotNull);
    await _expectHeroCropCompositionGuide(
      tester,
      expectedAspectRatio: expectedAccountProfileHeroCoverAspectRatio,
      bottomLabel: 'Nome e acoes',
      helper: 'Evite rostos, textos e marcas nas faixas de interface.',
    );
    expect(find.text('Área segura do hero'), findsNothing);
  });

  for (final scenario in <_CropSheetRatioCase>[
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.avatar,
      expectedTitle: 'Recortar avatar',
      expectedAspectRatio: 1.0,
      expectedCircleUi: true,
    ),
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.lightLogo,
      expectedTitle: 'Recortar logo claro',
      expectedAspectRatio: 18 / 5,
    ),
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.darkLogo,
      expectedTitle: 'Recortar logo escuro',
      expectedAspectRatio: 18 / 5,
    ),
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.lightIcon,
      expectedTitle: 'Recortar icone claro',
      expectedAspectRatio: 1.0,
    ),
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.darkIcon,
      expectedTitle: 'Recortar icone escuro',
      expectedAspectRatio: 1.0,
    ),
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.pwaIcon,
      expectedTitle: 'Recortar icone PWA',
      expectedAspectRatio: 1.0,
    ),
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.publicWebDefaultImage,
      expectedTitle: 'Recortar imagem de compartilhamento',
      expectedAspectRatio: tenantAdminPublicWebDefaultImageAspectRatio,
    ),
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.mapFilter,
      expectedTitle: 'Recortar imagem do filtro',
      expectedAspectRatio: 1.0,
    ),
    const _CropSheetRatioCase(
      slot: TenantAdminImageSlot.typeVisual,
      expectedTitle: 'Recortar imagem canônica do tipo',
      expectedAspectRatio: 1.0,
    ),
  ]) {
    testWidgets('crop sheet preserves ${scenario.slot.name} aspect ratio',
        (tester) async {
      final crop = await _openCropSheetForSlot(tester, scenario);
      expect(
        crop.aspectRatio,
        closeTo(scenario.expectedAspectRatio, 0.0001),
        reason: scenario.slot.name,
      );
      expect(
        crop.withCircleUi,
        scenario.expectedCircleUi,
        reason: scenario.slot.name,
      );
      if (scenario.slot == TenantAdminImageSlot.avatar) {
        expect(find.byKey(_heroCropCompositionGuideKey), findsNothing);
      }
    });
  }

  testWidgets('crop sheet uses canonical OG ratio for public web image',
      (tester) async {
    final bytes = _createPngBytes(width: 1200, height: 1800);
    final file = XFile.fromData(
      bytes,
      name: 'public_web_default.png',
      mimeType: 'image/png',
    );
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
                    slot: TenantAdminImageSlot.publicWebDefaultImage,
                    readBytesForCrop: service.readBytesForCrop,
                    prepareCroppedFile: (croppedData, slot) =>
                        service.prepareBytesAsXFile(
                      croppedData,
                      slot: slot,
                      applyAspectCrop: false,
                    ),
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
    expect(find.text('Recortar imagem de compartilhamento'), findsOneWidget);
    await _pumpUntilFound(tester, find.byType(Crop));

    expect(tester.takeException(), isNull);
    final crop = tester.widget<Crop>(find.byType(Crop));
    expect(
      crop.aspectRatio,
      closeTo(tenantAdminPublicWebDefaultImageAspectRatio, 0.0001),
    );
    expect(crop.withCircleUi, isFalse);
    expect(find.text('Usar'), findsOneWidget);
  });
}

Future<void> _expectHeroCropCompositionGuide(
  WidgetTester tester, {
  required double expectedAspectRatio,
  required String bottomLabel,
  required String helper,
}) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(seconds: 2));
  });
  await tester.pumpAndSettle();
  await _pumpUntilFound(
    tester,
    find.byKey(_heroCropCompositionGuideKey),
    maxPumps: 40,
  );
  expect(find.byKey(_heroCropTopInterfaceZoneKey), findsOneWidget);
  expect(find.byKey(_heroCropBottomInterfaceZoneKey), findsOneWidget);
  expect(find.byKey(_heroCropLeftBreathingZoneKey), findsOneWidget);
  expect(find.byKey(_heroCropRightBreathingZoneKey), findsOneWidget);
  expect(find.byKey(_heroCropFocusZoneKey), findsOneWidget);
  expect(find.text('Controles'), findsOneWidget);
  expect(find.text('Foco principal'), findsOneWidget);
  expect(find.text(bottomLabel), findsOneWidget);
  expect(find.text(helper), findsOneWidget);

  final guideSize = tester.getSize(find.byKey(_heroCropCompositionGuideKey));
  expect(
    guideSize.width / guideSize.height,
    closeTo(expectedAspectRatio, 0.03),
  );
}

Future<void> _pumpWithAutoRoute(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'crop-sheet-test',
        path: '/',
        builder: (_, _) => child,
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

Future<Crop> _openCropSheetForSlot(
  WidgetTester tester,
  _CropSheetRatioCase scenario,
) async {
  final bytes = _createPngBytes(width: 360, height: 540);
  final file = XFile.fromData(
    bytes,
    name: '${scenario.slot.name}.png',
    mimeType: 'image/png',
  );
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
                  slot: scenario.slot,
                  readBytesForCrop: service.readBytesForCrop,
                  prepareCroppedFile: (croppedData, slot) =>
                      service.prepareBytesAsXFile(
                    croppedData,
                    slot: slot,
                    applyAspectCrop: false,
                  ),
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
  expect(find.text(scenario.expectedTitle), findsOneWidget);
  await _pumpUntilFound(tester, find.byType(Crop));
  expect(tester.takeException(), isNull);
  return tester.widget<Crop>(find.byType(Crop));
}

Uint8List _createPngBytes({
  int width = 1600,
  int height = 900,
}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 45, 180));
  return Uint8List.fromList(img.encodePng(image));
}

class _CropSheetRatioCase {
  const _CropSheetRatioCase({
    required this.slot,
    required this.expectedTitle,
    required this.expectedAspectRatio,
    this.expectedCircleUi = false,
  });

  final TenantAdminImageSlot slot;
  final String expectedTitle;
  final double expectedAspectRatio;
  final bool expectedCircleUi;
}

class _FakeIngestionService extends TenantAdminImageIngestionService {
  _FakeIngestionService(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List> readBytesForCrop(XFile file) async => bytes;
}
