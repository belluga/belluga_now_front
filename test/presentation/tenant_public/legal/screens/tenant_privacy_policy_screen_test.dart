import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/presentation/tenant_public/legal/screens/tenant_privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
      'privacy policy visible back falls back to home when no history exists',
      (tester) async {
    final router = _RecordingStackRouter()..canPopResult = false;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: const TenantPrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
      router.replaceAllRoutes.single.single.routeName,
      TenantHomeRoute.name,
    );
  });

  testWidgets(
      'privacy policy system back falls back to home when no history exists',
      (tester) async {
    final router = _RecordingStackRouter()..canPopResult = false;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: const TenantPrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final popScope = tester.widget<PopScope<dynamic>>(
      find.byWidgetPredicate((widget) => widget is PopScope),
    );
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
      router.replaceAllRoutes.single.single.routeName,
      TenantHomeRoute.name,
    );
  });

  testWidgets('privacy policy visible back pops when history exists',
      (tester) async {
    final router = _RecordingStackRouter()..canPopResult = true;

    await tester.pumpWidget(
      _buildRoutedTestApp(
        router: router,
        child: const TenantPrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });
}

Widget _buildRoutedTestApp({
  required _RecordingStackRouter router,
  required Widget child,
}) {
  final routeData = RouteData(
    route: _FakeRouteMatch(
      name: TenantPrivacyPolicyRoute.name,
      fullPath: '/privacy-policy',
      meta: canonicalRouteMeta(
        family: CanonicalRouteFamily.tenantPrivacyPolicy,
      ),
    ),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const [],
    type: const RouteType.material(),
  );

  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: RouteDataScope(
        routeData: routeData,
        child: child,
      ),
    ),
  );
}

class _RecordingStackRouter extends Fake implements StackRouter {
  bool canPopResult = false;
  int canPopCallCount = 0;
  int popCallCount = 0;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes =
      <List<PageRouteInfo<dynamic>>>[];

  @override
  RootStackRouter get root => _FakeRootStackRouter('/privacy-policy');

  @override
  bool canPop({
    bool ignoreChildRoutes = false,
    bool ignoreParentRoutes = false,
    bool ignorePagelessRoutes = false,
  }) {
    canPopCallCount += 1;
    return canPopResult;
  }

  @override
  void pop<T extends Object?>([T? result]) {
    popCallCount += 1;
  }

  @override
  Future<void> replaceAll(
    List<PageRouteInfo<dynamic>> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllRoutes.add(routes);
  }
}

class _FakeRootStackRouter extends Fake implements RootStackRouter {
  _FakeRootStackRouter(this.currentPath);

  @override
  final String currentPath;

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.name,
    required this.fullPath,
    required this.meta,
    PageRouteInfo<dynamic>? pageRouteInfo,
  }) : pageRouteInfo = pageRouteInfo ?? const TenantPrivacyPolicyRoute();

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}
