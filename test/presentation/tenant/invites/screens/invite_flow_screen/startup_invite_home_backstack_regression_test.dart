import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_coordinator.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('startup invite terminal canonical back preserves one Home route', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: <AutoRoute>[
        // Keep the generated route identities while substituting inert page
        // builders. This is the smallest actual-router composition: bringing up
        // the production module pages would require unrelated feature modules.
        AutoRoute(
          path: '/',
          page: PageInfo(
            TenantHomeRoute.name,
            builder: (_) => const SizedBox(),
          ),
        ),
        AutoRoute(
          path: '/invite',
          page: PageInfo(
            InviteFlowRoute.name,
            builder: (_) => const SizedBox(),
          ),
        ),
      ],
    );
    final coordinator = AppStartupNavigationCoordinator(
      planLoader: () async => AppStartupNavigationPlan.routes(
        const <PageRouteInfo<dynamic>>[TenantHomeRoute(), InviteFlowRoute()],
      ),
    );
    await coordinator.initialize();
    final delegate = router.delegate(
      deepLinkBuilder: coordinator.resolvePlatformDeepLink,
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerDelegate: delegate,
        routeInformationParser: router.defaultRouteParser(),
      ),
    );
    await delegate.setInitialRoutePath(
      await router.defaultRouteParser().parseRouteInformation(
        RouteInformation(uri: Uri(path: '/')),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.currentHierarchy().map((route) => route.name), <String>[
      TenantHomeRoute.name,
      InviteFlowRoute.name,
    ]);

    // The product coordinator delegates terminal no-continuation navigation to
    // AutoRoute's canonical back policy. Exercise that same router operation:
    // popping Navigator directly leaves the declarative RootStackRouter state
    // unchanged in this lightweight harness.
    router.pop();
    await tester.pumpAndSettle();

    expect(router.currentHierarchy().map((route) => route.name), <String>[
      TenantHomeRoute.name,
    ]);
    expect(router.currentPath, '/');
  });
}
