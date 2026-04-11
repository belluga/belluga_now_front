import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_coordinator.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_plan.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'startup coordinator applies pending invite stack on root entry',
    (tester) async {
      final router = _buildRouter();
      final coordinator = AppStartupNavigationCoordinator(
        planLoader: () async => AppStartupNavigationPlan.routes(
          const <PageRouteInfo<dynamic>>[
            TenantHomeRoute(),
            InviteFlowRoute(),
          ],
        ),
      );
      await coordinator.initialize();
      final delegate = router.delegate(
        deepLinkBuilder: coordinator.resolvePlatformDeepLink,
      );

      final configuration = await _parseRoute(router, '/');
      await delegate.setInitialRoutePath(configuration);

      expect(
        router.currentHierarchy().map((segment) => segment.name).toList(),
        <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
        ],
      );
      expect(router.currentPath, '/invite');
    },
  );

  testWidgets(
    'startup coordinator ignores non-root deep links and consumes the override only once',
    (tester) async {
      final coordinator = AppStartupNavigationCoordinator(
        planLoader: () async => AppStartupNavigationPlan.routes(
          const <PageRouteInfo<dynamic>>[
            TenantHomeRoute(),
            InviteFlowRoute(),
          ],
        ),
      );
      await coordinator.initialize();
      final firstRouter = _buildRouter();
      final firstDelegate = firstRouter.delegate(
        deepLinkBuilder: coordinator.resolvePlatformDeepLink,
      );

      await firstDelegate.setInitialRoutePath(
        await _parseRoute(firstRouter, '/parceiro/ananda-torres'),
      );

      expect(
        firstRouter.currentHierarchy().map((segment) => segment.name).toList(),
        <String>[PartnerDetailRoute.name],
      );

      final secondRouter = _buildRouter();
      final secondDelegate = secondRouter.delegate(
        deepLinkBuilder: coordinator.resolvePlatformDeepLink,
      );
      await secondDelegate
          .setInitialRoutePath(await _parseRoute(secondRouter, '/'));

      expect(
        secondRouter.currentHierarchy().map((segment) => segment.name).toList(),
        <String>[TenantHomeRoute.name],
      );
      expect(secondRouter.currentPath, '/');
    },
  );

  testWidgets(
    'startup coordinator applies deferred path override only on root entry',
    (tester) async {
      final router = _buildRouter();
      final coordinator = AppStartupNavigationCoordinator(
        planLoader: () async =>
            const AppStartupNavigationPlan.path('/invite?code=ABCD1234'),
      );
      await coordinator.initialize();
      final delegate = router.delegate(
        deepLinkBuilder: coordinator.resolvePlatformDeepLink,
      );

      await delegate.setInitialRoutePath(await _parseRoute(router, '/'));

      expect(
        router.currentHierarchy().map((segment) => segment.name).toList(),
        <String>[
          TenantHomeRoute.name,
          InviteFlowRoute.name,
        ],
      );
      expect(router.currentPath, '/invite');
      expect(router.currentUrl, '/invite?code=ABCD1234');
    },
  );
}

RootStackRouter _buildRouter() {
  return RootStackRouter.build(
    routes: <AutoRoute>[
      AutoRoute(
        path: '/',
        page: TenantHomeRoute.page,
      ),
      AutoRoute(
        path: '/invite',
        page: InviteFlowRoute.page,
      ),
      AutoRoute(
        path: '/parceiro/:slug',
        page: PartnerDetailRoute.page,
      ),
    ],
  );
}

Future<UrlState> _parseRoute(
  RootStackRouter router,
  String path,
) {
  return router
      .defaultRouteParser(
        includePrefixMatches: false,
      )
      .parseRouteInformation(
        RouteInformation(uri: Uri.parse(path)),
      );
}
