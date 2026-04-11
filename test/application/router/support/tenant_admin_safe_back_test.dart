import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/tenant_admin_safe_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tenant admin current back policy pops when history exists',
      (tester) async {
    final router = _RecordingStackRouter(canPopResult: true);
    late RouteBackPolicy policy;

    await tester.pumpWidget(
      _buildPolicyHarness(
        router: router,
        routeData: _buildRouteData(
          router: router,
          routeName: TenantAdminAccountDetailRoute.name,
          fullPath: '/admin/accounts/account-alpha',
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.tenantAdminAccountsInternal,
            chromeMode: RouteChromeMode.fullscreen,
          ),
        ),
        onPolicyReady: (value) => policy = value,
      ),
    );

    policy.handleBack();
    await tester.pump();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 1);
    expect(router.replaceAllRoutes, isEmpty);
  });

  testWidgets(
      'tenant admin current back policy falls back to section root when no history exists',
      (tester) async {
    final router = _RecordingStackRouter(canPopResult: false);
    late RouteBackPolicy policy;

    await tester.pumpWidget(
      _buildPolicyHarness(
        router: router,
        routeData: _buildRouteData(
          router: router,
          routeName: TenantAdminStaticAssetDetailRoute.name,
          fullPath: '/admin/assets/asset-1',
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.tenantAdminAssetsInternal,
            chromeMode: RouteChromeMode.fullscreen,
          ),
        ),
        onPolicyReady: (value) => policy = value,
      ),
    );

    policy.handleBack();
    await tester.pump();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replacedRoute, isNotNull);
    expect(
      router.replacedRoute?.routeName,
      TenantAdminStaticAssetsListRoute.name,
    );
  });

  testWidgets(
      'tenant admin current back policy respects explicit fallback override',
      (tester) async {
    final router = _RecordingStackRouter(canPopResult: false);
    late RouteBackPolicy policy;

    await tester.pumpWidget(
      _buildPolicyHarness(
        router: router,
        routeData: _buildRouteData(
          router: router,
          routeName: TenantAdminLocationPickerRoute.name,
          fullPath: '/admin/accounts/location-picker',
          meta: canonicalRouteMeta(
            family: CanonicalRouteFamily.tenantAdminAccountsInternal,
            chromeMode: RouteChromeMode.fullscreen,
          ),
        ),
        fallbackRoute: const TenantAdminSettingsLocalPreferencesRoute(),
        onPolicyReady: (value) => policy = value,
      ),
    );

    policy.handleBack();
    await tester.pump();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replacedRoute, isNotNull);
    expect(
      router.replacedRoute?.routeName,
      TenantAdminSettingsLocalPreferencesRoute.name,
    );
  });

  testWidgets(
      'tenant admin current back policy falls back safely without RouteDataScope',
      (tester) async {
    final router = _RecordingStackRouter(canPopResult: false);
    late RouteBackPolicy policy;

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              policy = buildTenantAdminCurrentRouteBackPolicy(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    policy.handleBack();
    await tester.pump();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
      router.replaceAllRoutes.single.single.routeName,
      TenantAdminDashboardRoute.name,
    );
  });

  testWidgets(
      'tenant admin perform back uses the same compat fallback without RouteDataScope',
      (tester) async {
    final router = _RecordingStackRouter(canPopResult: false);
    late BuildContext capturedContext;

    await tester.pumpWidget(
      StackRouterScope(
        controller: router,
        stateHash: 0,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    performTenantAdminCurrentRouteBack(capturedContext);
    await tester.pump();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replaceAllRoutes, hasLength(1));
    expect(
      router.replaceAllRoutes.single.single.routeName,
      TenantAdminDashboardRoute.name,
    );
  });

  testWidgets(
      'tenant admin current back policy is a no-op compat policy without AutoRoute scopes',
      (tester) async {
    late RouteBackPolicy policy;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            policy = buildTenantAdminCurrentRouteBackPolicy(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(policy.surfaceKind, BackSurfaceKind.internalOnly);
    expect(policy.handleBack, returnsNormally);
  });
}

Widget _buildPolicyHarness({
  required _RecordingStackRouter router,
  required RouteData routeData,
  PageRouteInfo<dynamic>? fallbackRoute,
  required void Function(RouteBackPolicy policy) onPolicyReady,
}) {
  return StackRouterScope(
    controller: router,
    stateHash: 0,
    child: MaterialApp(
      home: RouteDataScope(
        routeData: routeData,
        child: Builder(
          builder: (context) {
            onPolicyReady(
              buildTenantAdminCurrentRouteBackPolicy(
                context,
                fallbackRoute: fallbackRoute,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
}

RouteData _buildRouteData({
  required StackRouter router,
  required String routeName,
  required String fullPath,
  required Map<String, dynamic> meta,
}) {
  return RouteData(
    route: _FakeRouteMatch(
      name: routeName,
      fullPath: fullPath,
      meta: meta,
    ),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const <RouteMatch>[],
    type: const RouteType.material(),
  );
}

class _RecordingStackRouter extends Fake implements StackRouter {
  _RecordingStackRouter({required this.canPopResult});

  final bool canPopResult;
  int canPopCallCount = 0;
  int popCallCount = 0;
  PageRouteInfo<dynamic>? replacedRoute;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes =
      <List<PageRouteInfo<dynamic>>>[];

  @override
  RootStackRouter get root => _FakeRootStackRouter('/admin');

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
  Future<T?> replace<T extends Object?>(
    PageRouteInfo route, {
    OnNavigationFailure? onFailure,
    bool notify = true,
  }) async {
    replacedRoute = route;
    return null;
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
  }) : pageRouteInfo =
          pageRouteInfo ?? const TenantAdminAccountsListRoute();

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
