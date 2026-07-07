import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/icons/boora_icons.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_header_delegate.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/immersive_detail_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_hero_action.dart';
import 'package:belluga_now/presentation/shared/widgets/immersive_detail_screen/models/immersive_tab_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  test('ImmersiveHeroAction resolves active icon and foreground color', () {
    const inactiveAction = ImmersiveHeroAction(
      key: Key('inactive'),
      label: 'Favoritar',
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      foregroundColor: Colors.black,
      activeForegroundColor: Colors.red,
      onPressed: null,
    );
    const activeAction = ImmersiveHeroAction(
      key: Key('active'),
      label: 'Favoritado',
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      isActive: true,
      foregroundColor: Colors.black,
      activeForegroundColor: Colors.red,
      onPressed: null,
    );

    expect(inactiveAction.resolvedIcon, Icons.favorite_border);
    expect(inactiveAction.resolvedForegroundColor, Colors.black);
    expect(activeAction.resolvedIcon, Icons.favorite);
    expect(activeAction.resolvedForegroundColor, Colors.red);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  testWidgets(
    'hero viewport fraction controls the shared sliver app bar height',
    (tester) async {
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Profile',
          heroViewportHeightFactor: 0.8,
          backPolicy: _FakeBackPolicy(),
          heroContent: Container(color: Colors.black),
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: const SizedBox(height: 200, child: Text('Section')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final appBar = tester.widget<SliverAppBar>(find.byType(SliverAppBar));
      expect(appBar.expandedHeight, 640);
    },
  );

  testWidgets(
    'tab header is flat before it overlaps content and elevated when pinned',
    (tester) async {
      Widget buildHeader({required bool overlapsContent}) {
        return MaterialApp(
          home: Builder(
            builder: (context) {
              return ImmersiveHeaderDelegate(
                tabs: const ['Sobre', 'Como Chegar'],
                currentTabIndex: 0,
                onTabTapped: (_) {},
              ).build(context, 0, overlapsContent);
            },
          ),
        );
      }

      await tester.pumpWidget(buildHeader(overlapsContent: false));

      expect(tester.widget<Material>(find.byType(Material)).elevation, 0);

      await tester.pumpWidget(buildHeader(overlapsContent: true));

      expect(tester.widget<Material>(find.byType(Material)).elevation, 4);
    },
  );

  test(
    'tab header rebuilds when labels change without changing tab count',
    () {
      final oldDelegate = ImmersiveHeaderDelegate(
        tabs: const ['Sobre', 'Programação', 'Palco Sexta', 'Como Chegar'],
        currentTabIndex: 1,
        onTabTapped: (_) {},
      );
      final newDelegate = ImmersiveHeaderDelegate(
        tabs: const ['Sobre', 'Programação', 'Palco Sábado', 'Como Chegar'],
        currentTabIndex: 1,
        onTabTapped: (_) {},
      );

      expect(newDelegate.shouldRebuild(oldDelegate), isTrue);
    },
  );

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
    'tabs expose named semantic button targets that activate sections',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
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
                content: const SizedBox(height: 400, child: Text('Sobre body')),
              ),
              ImmersiveTabItem(
                title: 'Como Chegar',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      key: const Key('semanticTabSectionStart'),
                      padding: const EdgeInsets.all(16),
                      child: const Text('Como Chegar body'),
                    ),
                    Container(height: 600, color: Colors.blue),
                  ],
                ),
              ),
            ],
          ),
        );

        await tester.pumpAndSettle();

        final tabAction = find.bySemanticsLabel(RegExp('Como Chegar')).first;
        expect(tabAction, findsOneWidget);
        expect(
          tester.getSemantics(tabAction),
          matchesSemantics(
            label: 'Como Chegar',
            isButton: true,
            isFocusable: true,
            hasSelectedState: true,
            hasTapAction: true,
            hasFocusAction: true,
          ),
        );

        await tester.tap(tabAction);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        final tabBottom = tester
            .getBottomLeft(find.byKey(const Key('immersiveTabSelected_1')))
            .dy;
        final sectionStartTop = tester
            .getTopLeft(find.byKey(const Key('semanticTabSectionStart')))
            .dy;

        expect(sectionStartTop, greaterThanOrEqualTo(tabBottom - 1));
        expect(sectionStartTop, lessThanOrEqualTo(tabBottom + 8));
      } finally {
        semantics.dispose();
      }
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
    'expanded hero renders the declared actions as an overlay rail',
    (tester) async {
      var primaryCalls = 0;
      var shareCalls = 0;
      var whatsappCalls = 0;

      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Profile',
          backPolicy: _FakeBackPolicy(),
          heroContent: Container(color: Colors.black),
          heroActions: [
            ImmersiveHeroAction(
              key: const Key('testPrimaryHeroAction'),
              label: 'Favoritar',
              icon: Icons.favorite_border,
              isPrimary: true,
              onPressed: () => primaryCalls += 1,
            ),
            ImmersiveHeroAction(
              key: const Key('testShareHeroAction'),
              label: 'Compartilhar',
              icon: Icons.share,
              onPressed: () => shareCalls += 1,
            ),
            ImmersiveHeroAction(
              key: const Key('testWhatsappHeroAction'),
              label: 'WhatsApp',
              icon: BooraIcons.whatsapp,
              onPressed: () => whatsappCalls += 1,
            ),
          ],
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: const SizedBox(height: 800, child: Text('Section')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('testPrimaryHeroAction')), findsOneWidget);
      expect(find.byKey(const Key('testShareHeroAction')), findsOneWidget);
      expect(find.byKey(const Key('testWhatsappHeroAction')), findsOneWidget);
      expect(find.byKey(const Key('immersiveHeroMoreAction')), findsNothing);

      final backTop = tester.getTopLeft(find.byIcon(Icons.arrow_back)).dy;
      final primaryTop =
          tester.getTopLeft(find.byKey(const Key('testPrimaryHeroAction'))).dy;
      expect(primaryTop, greaterThanOrEqualTo(0));
      expect(primaryTop, lessThanOrEqualTo(backTop + 12));

      await tester.tap(find.byKey(const Key('testWhatsappHeroAction')));
      await tester.pumpAndSettle();

      expect(primaryCalls, 0);
      expect(shareCalls, 0);
      expect(whatsappCalls, 1);
    },
  );

  testWidgets(
    'collapsed hero keeps primary action visible and moves secondary actions to more',
    (tester) async {
      var primaryCalls = 0;
      var shareCalls = 0;

      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Profile',
          backPolicy: _FakeBackPolicy(),
          heroContent: Container(color: Colors.black),
          heroActions: [
            ImmersiveHeroAction(
              key: const Key('testCollapsedPrimaryAction'),
              label: 'Convidar',
              icon: Icons.mail_outline,
              isPrimary: true,
              onPressed: () => primaryCalls += 1,
            ),
            ImmersiveHeroAction(
              key: const Key('testCollapsedShareAction'),
              label: 'Compartilhar',
              icon: Icons.share,
              onPressed: () => shareCalls += 1,
            ),
          ],
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: const SizedBox(height: 1200, child: Text('Section')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('immersiveSwipeSurface')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('testCollapsedPrimaryAction')), findsOneWidget);
      expect(find.byKey(const Key('immersiveHeroMoreAction')), findsOneWidget);
      expect(find.byKey(const Key('testCollapsedShareAction')), findsNothing);

      await tester.tap(find.byKey(const Key('testCollapsedPrimaryAction')));
      await tester.pumpAndSettle();
      expect(primaryCalls, 1);

      await tester.tap(find.byKey(const Key('immersiveHeroMoreAction')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Compartilhar').last);
      await tester.pumpAndSettle();

      expect(shareCalls, 1);
    },
  );

  testWidgets(
    'partially collapsed hero keeps expanded chrome until content is clear',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Long Profile Title',
          collapsedToolbarHeight: 72,
          centerCollapsedTitle: false,
          backPolicy: _FakeBackPolicy(),
          heroContent: Stack(
            children: [
              Container(color: Colors.black),
              const Positioned(
                left: 16,
                bottom: 24,
                child: Text('Expanded hero title'),
              ),
            ],
          ),
          heroActions: [
            ImmersiveHeroAction(
              key: const Key('testPartialPrimaryAction'),
              label: 'Favoritar',
              icon: Icons.favorite_border,
              isPrimary: true,
              onPressed: () {},
            ),
            ImmersiveHeroAction(
              key: const Key('testPartialShareAction'),
              label: 'Compartilhar',
              icon: Icons.share,
              onPressed: () {},
            ),
          ],
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: const SizedBox(height: 1400, child: Text('Section')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('immersiveSwipeSurface')),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('immersiveCollapsedToolbarScrim')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('immersiveCollapsedTitle')),
        findsNothing,
      );
      expect(find.byKey(const Key('testPartialPrimaryAction')), findsOneWidget);
      expect(find.byKey(const Key('testPartialShareAction')), findsOneWidget);
      expect(find.byKey(const Key('immersiveHeroMoreAction')), findsNothing);

      await tester.drag(
        find.byKey(const Key('immersiveSwipeSurface')),
        const Offset(0, -700),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('immersiveCollapsedTitle')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('testPartialPrimaryAction')), findsOneWidget);
      expect(find.byKey(const Key('testPartialShareAction')), findsNothing);
      expect(find.byKey(const Key('immersiveHeroMoreAction')), findsOneWidget);
    },
  );

  testWidgets(
    'collapsed hero uses the first action when no primary is declared',
    (tester) async {
      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Profile',
          backPolicy: _FakeBackPolicy(),
          heroContent: Container(color: Colors.black),
          heroActions: [
            ImmersiveHeroAction(
              key: const Key('testFirstFallbackAction'),
              label: 'Primeira',
              icon: Icons.looks_one,
              onPressed: () {},
            ),
            ImmersiveHeroAction(
              key: const Key('testSecondFallbackAction'),
              label: 'Segunda',
              icon: Icons.looks_two,
              onPressed: () {},
            ),
          ],
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: const SizedBox(height: 1200, child: Text('Section')),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const Key('immersiveSwipeSurface')),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('testFirstFallbackAction')), findsOneWidget);
      expect(find.byKey(const Key('testSecondFallbackAction')), findsNothing);
      expect(find.byKey(const Key('immersiveHeroMoreAction')), findsOneWidget);
    },
  );

  testWidgets(
    'hero action loading state renders a spinner with the legacy share key',
    (tester) async {
      await _pumpImmersiveScreen(
        tester,
        ImmersiveDetailScreen(
          title: 'Profile',
          backPolicy: _FakeBackPolicy(),
          heroContent: Container(color: Colors.black),
          heroActions: const [
            ImmersiveHeroAction(
              key: Key('immersiveShareAction'),
              label: 'Compartilhar',
              icon: Icons.share,
              isPrimary: true,
              isLoading: true,
              onPressed: null,
            ),
          ],
          tabs: [
            ImmersiveTabItem(
              title: 'Sobre',
              content: SizedBox(height: 800, child: Text('Section')),
            ),
          ],
        ),
      );

      await tester.pump();

      expect(find.byKey(const Key('immersiveShareAction')), findsOneWidget);
      expect(
        find.byKey(const Key('immersiveShareActionLoading')),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
        builder: (_, _) => child,
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
