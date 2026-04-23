import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
    'tab tap keeps the target section start visible with taller collapsed app bar',
    (tester) async {
      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Profile',
          collapsedToolbarHeight: 72,
          backPolicy: _FakeBackPolicy(),
          heroContent: Container(color: Colors.black),
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: const Key('sectionOneStart'),
                    padding: const EdgeInsets.all(16),
                    child: const Text('Section 1 Start'),
                  ),
                  Container(height: 900, color: Colors.red),
                ],
              ),
            ),
            ImmersiveTabItem(
              title: 'Agenda',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: const Key('sectionTwoStart'),
                    padding: const EdgeInsets.all(16),
                    child: const Text('Section 2 Start'),
                  ),
                  Container(height: 600, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('immersiveTab_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final tabBottom = tester
          .getBottomLeft(find.byKey(const Key('immersiveTabSelected_1')))
          .dy;
      final sectionStartTop =
          tester.getTopLeft(find.byKey(const Key('sectionTwoStart'))).dy;

      expect(sectionStartTop, greaterThanOrEqualTo(tabBottom - 1));
      expect(sectionStartTop, lessThanOrEqualTo(tabBottom + 8));
    },
  );

  testWidgets(
    'initial tab index scrolls to the requested section after first layout',
    (tester) async {
      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Event',
          collapsedToolbarHeight: 72,
          initialTabIndex: 1,
          backPolicy: _FakeBackPolicy(),
          heroContent: Container(color: Colors.black),
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: const Key('initialFirstSectionStart'),
                    padding: const EdgeInsets.all(16),
                    child: const Text('Initial Section 1 Start'),
                  ),
                  Container(height: 900, color: Colors.red),
                ],
              ),
            ),
            ImmersiveTabItem(
              title: 'Programação',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: const Key('initialSecondSectionStart'),
                    padding: const EdgeInsets.all(16),
                    child: const Text('Initial Section 2 Start'),
                  ),
                  Container(height: 600, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      final tabBottom = tester
          .getBottomLeft(find.byKey(const Key('immersiveTabSelected_1')))
          .dy;
      final sectionStartTop = tester
          .getTopLeft(find.byKey(const Key('initialSecondSectionStart')))
          .dy;

      expect(sectionStartTop, greaterThanOrEqualTo(tabBottom - 1));
      expect(sectionStartTop, lessThanOrEqualTo(tabBottom + 8));
    },
  );

  testWidgets(
    'returning to first tab resets immersive scroll to the real top',
    (tester) async {
      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Event',
          collapsedToolbarHeight: 72,
          backPolicy: _FakeBackPolicy(),
          heroContent: Stack(
            children: [
              Container(color: Colors.black),
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  key: const Key('heroTopMarker'),
                  width: 24,
                  height: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: const Key('firstSectionStart'),
                    padding: const EdgeInsets.all(16),
                    child: const Text('First Section'),
                  ),
                  Container(height: 900, color: Colors.red),
                ],
              ),
            ),
            ImmersiveTabItem(
              title: 'Artists',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: const Key('secondSectionStart'),
                    padding: const EdgeInsets.all(16),
                    child: const Text('Second Section'),
                  ),
                  Container(height: 900, color: Colors.blue),
                ],
              ),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('immersiveTab_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('immersiveTab_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      final heroTop =
          tester.getTopLeft(find.byKey(const Key('heroTopMarker'))).dy;

      expect(heroTop, greaterThanOrEqualTo(0));
      expect(heroTop, lessThanOrEqualTo(24));
    },
  );

  testWidgets(
    'visible back delegates to the configured back policy',
    (tester) async {
      final backPolicy = _FakeBackPolicy();

      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Profile',
          backPolicy: backPolicy,
          heroContent: Container(color: Colors.black),
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: SizedBox(height: 200, child: Text('Section')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(backPolicy.callCount, 1);
    },
  );

  testWidgets(
    'system back delegates to the configured back policy',
    (tester) async {
      final backPolicy = _FakeBackPolicy();

      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Profile',
          backPolicy: backPolicy,
          heroContent: Container(color: Colors.black),
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: SizedBox(height: 200, child: Text('Section')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final popScope = tester.widget<PopScope<dynamic>>(
        find.byWidgetPredicate((widget) => widget is PopScope),
      );
      popScope.onPopInvokedWithResult?.call(false, null);
      await tester.pumpAndSettle();

      expect(backPolicy.callCount, 1);
    },
  );
}

Future<void> _pumpImmersiveScreen(
  WidgetTester tester,
  ImmersiveDetailScreen child,
) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'immersive-detail-test',
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.immersiveEventDetail,
        ),
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
}

class _FakeBackPolicy implements RouteBackPolicy {
  int callCount = 0;

  @override
  BackSurfaceKind get surfaceKind => BackSurfaceKind.rootOpenable;

  @override
  void handleBack() {
    callCount += 1;
  }
}
