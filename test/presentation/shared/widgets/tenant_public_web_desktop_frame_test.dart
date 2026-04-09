import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/shared/widgets/tenant_public_web_desktop_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TenantPublicWebDesktopFrame route scope', () {
    test('frames the approved tenant-public route family', () {
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(TenantHomeRoute.name),
        isTrue,
      );
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(
          ImmersiveEventDetailRoute.name,
        ),
        isTrue,
      );
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(EventSearchRoute.name),
        isTrue,
      );
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(AppPromotionRoute.name),
        isTrue,
      );
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(
            LocationPermissionRoute.name),
        isTrue,
      );
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(InviteShareRoute.name),
        isTrue,
      );
    });

    test('does not frame admin or landlord routes', () {
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(
            TenantAdminShellRoute.name),
        isFalse,
      );
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(LandlordHomeRoute.name),
        isFalse,
      );
      expect(
        TenantPublicWebDesktopFrame.shouldFrameRoute(AuthLoginRoute.name),
        isFalse,
      );
    });
  });

  group('TenantPublicWebDesktopFrame layout', () {
    const childKey = Key('framed-child');

    Future<void> pumpFrame(
      WidgetTester tester, {
      required String routeName,
      required bool isWebRuntime,
      required Size viewportSize,
    }) async {
      await tester.binding.setSurfaceSize(viewportSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: TenantPublicWebDesktopFrame(
            routeName: routeName,
            isWebRuntime: isWebRuntime,
            child: Container(
              key: childKey,
              width: double.infinity,
              height: 40,
              color: Colors.red,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('constrains in-scope web routes on wide viewports', (
      tester,
    ) async {
      await pumpFrame(
        tester,
        routeName: TenantHomeRoute.name,
        isWebRuntime: true,
        viewportSize: const Size(1200, 800),
      );

      expect(tester.getSize(find.byKey(childKey)).width, 430);
    });

    testWidgets('keeps in-scope web routes full width on narrow viewports', (
      tester,
    ) async {
      await pumpFrame(
        tester,
        routeName: TenantHomeRoute.name,
        isWebRuntime: true,
        viewportSize: const Size(390, 800),
      );

      expect(tester.getSize(find.byKey(childKey)).width, 390);
    });

    testWidgets('does not constrain out-of-scope routes', (tester) async {
      await pumpFrame(
        tester,
        routeName: TenantAdminShellRoute.name,
        isWebRuntime: true,
        viewportSize: const Size(1200, 800),
      );

      expect(tester.getSize(find.byKey(childKey)).width, 1200);
    });
  });
}
