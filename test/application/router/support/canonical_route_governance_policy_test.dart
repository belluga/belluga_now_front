import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  for (final testCase in _policyCases) {
    testWidgets(
      '${testCase.description} uses the canonical no-history outcome',
      (tester) async {
        final router = _RecordingRootStackRouter(
          currentPath: testCase.currentPath,
          canPopResult: false,
        );
        var exitRequests = 0;
        late RouteBackPolicy policy;

        await tester.pumpWidget(
          _buildPolicyHarness(
            router: router,
            routeData: _buildRouteData(
              router: router,
              routeName: testCase.routeName,
              fullPath: testCase.fullPath,
              meta: canonicalRouteMeta(family: testCase.family),
              pageRouteInfo: testCase.pageRouteInfo,
              queryParams: testCase.queryParams,
            ),
            requestExit: () => exitRequests += 1,
            onPolicyReady: (value) => policy = value,
          ),
        );

        policy.handleBack();
        await tester.pump();

        expect(router.canPopCallCount, 1);
        expect(router.popCallCount, 0);

        switch (testCase.noHistoryBehavior) {
          case _NoHistoryBehavior.replaceAll:
            expect(exitRequests, 0);
            expect(router.replacedRoute, isNull);
            expect(router.replaceAllRoutes, hasLength(1));
            expect(
              router.replaceAllRoutes.single.single.routeName,
              testCase.expectedRouteName,
            );
          case _NoHistoryBehavior.replace:
            expect(exitRequests, 0);
            expect(router.replaceAllRoutes, isEmpty);
            expect(router.replacedRoute, isNotNull);
            expect(router.replacedRoute?.routeName, testCase.expectedRouteName);
          case _NoHistoryBehavior.requestExit:
            expect(exitRequests, 1);
            expect(router.replacedRoute, isNull);
            expect(router.replaceAllRoutes, isEmpty);
        }
      },
    );

    testWidgets(
      '${testCase.description} pops when prior history exists',
      (tester) async {
        final router = _RecordingRootStackRouter(
          currentPath: testCase.currentPath,
          canPopResult: true,
        );
        var exitRequests = 0;
        late RouteBackPolicy policy;

        await tester.pumpWidget(
          _buildPolicyHarness(
            router: router,
            routeData: _buildRouteData(
              router: router,
              routeName: testCase.routeName,
              fullPath: testCase.fullPath,
              meta: canonicalRouteMeta(family: testCase.family),
              pageRouteInfo: testCase.pageRouteInfo,
              queryParams: testCase.queryParams,
            ),
            requestExit: () => exitRequests += 1,
            onPolicyReady: (value) => policy = value,
          ),
        );

        policy.handleBack();
        await tester.pump();

        expect(router.canPopCallCount, 1);
        expect(router.popCallCount, 1);
        expect(exitRequests, 0);
        expect(router.replacedRoute, isNull);
        expect(router.replaceAllRoutes, isEmpty);
      },
    );
  }

  testWidgets(
      'explicit route data policy resolves the active child route even when the ambient shell route is unclassified',
      (tester) async {
    final router = _RecordingRootStackRouter(
      currentPath: '/admin/events/criar',
      canPopResult: false,
    );
    final childRouteData = _buildRouteData(
      router: router,
      routeName: TenantAdminEventCreateRoute.name,
      fullPath: '/admin/events/criar',
      meta: canonicalRouteMeta(
        family: CanonicalRouteFamily.tenantAdminEventsInternal,
      ),
      pageRouteInfo: const TenantAdminEventCreateRoute(),
    );

    final policy = buildCanonicalRouteBackPolicyForRouteData(
      routeData: childRouteData,
    );

    policy.handleBack();
    await tester.pump();

    expect(router.canPopCallCount, 1);
    expect(router.popCallCount, 0);
    expect(router.replacedRoute?.routeName, TenantAdminEventsRoute.name);
    expect(router.replaceAllRoutes, isEmpty);
  });

  testWidgets('missing canonical route meta fails fast', (tester) async {
    final router = _RecordingRootStackRouter(
      currentPath: '/missing-meta',
      canPopResult: false,
    );

    await tester.pumpWidget(
      _buildPolicyHarness(
        router: router,
        routeData: _buildRouteData(
          router: router,
          routeName: TenantHomeRoute.name,
          fullPath: '/',
          meta: const <String, dynamic>{},
          pageRouteInfo: const TenantHomeRoute(),
        ),
        onPolicyReady: (_) {},
      ),
    );

    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect(
      (error as StateError).message,
      contains('missing canonicalRouteMeta'),
    );
  });
}

Widget _buildPolicyHarness({
  required _RecordingRootStackRouter router,
  required RouteData routeData,
  required void Function(RouteBackPolicy policy) onPolicyReady,
  RouteNoHistoryDelegate? requestExit,
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
              buildCanonicalCurrentRouteBackPolicy(
                context,
                requestExit: requestExit,
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
  required RootStackRouter router,
  required String routeName,
  required String fullPath,
  required Map<String, dynamic> meta,
  required PageRouteInfo<dynamic> pageRouteInfo,
  Map<String, dynamic> queryParams = const <String, dynamic>{},
}) {
  return RouteData(
    route: _FakeRouteMatch(
      name: routeName,
      fullPath: fullPath,
      meta: meta,
      pageRouteInfo: pageRouteInfo,
      queryParams: queryParams,
    ),
    router: router,
    stackKey: const ValueKey<String>('stack'),
    pendingChildren: const <RouteMatch>[],
    type: const RouteType.material(),
  );
}

enum _NoHistoryBehavior {
  replaceAll,
  replace,
  requestExit,
}

final class _PolicyCase {
  const _PolicyCase({
    required this.description,
    required this.family,
    required this.routeName,
    required this.fullPath,
    required this.currentPath,
    required this.pageRouteInfo,
    required this.noHistoryBehavior,
    this.expectedRouteName,
    this.queryParams = const <String, dynamic>{},
  });

  final String description;
  final CanonicalRouteFamily family;
  final String routeName;
  final String fullPath;
  final String currentPath;
  final PageRouteInfo<dynamic> pageRouteInfo;
  final _NoHistoryBehavior noHistoryBehavior;
  final String? expectedRouteName;
  final Map<String, dynamic> queryParams;
}

final List<_PolicyCase> _policyCases = <_PolicyCase>[
  const _PolicyCase(
    description: 'tenant home',
    family: CanonicalRouteFamily.tenantHome,
    routeName: TenantHomeRoute.name,
    fullPath: '/',
    currentPath: '/',
    pageRouteInfo: TenantHomeRoute(),
    noHistoryBehavior: _NoHistoryBehavior.requestExit,
  ),
  const _PolicyCase(
    description: 'privacy policy',
    family: CanonicalRouteFamily.tenantPrivacyPolicy,
    routeName: TenantPrivacyPolicyRoute.name,
    fullPath: '/privacy-policy',
    currentPath: '/privacy-policy',
    pageRouteInfo: TenantPrivacyPolicyRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  const _PolicyCase(
    description: 'discovery root',
    family: CanonicalRouteFamily.discoveryRoot,
    routeName: DiscoveryRoute.name,
    fullPath: '/descobrir',
    currentPath: '/descobrir',
    pageRouteInfo: DiscoveryRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  _PolicyCase(
    description: 'partner detail',
    family: CanonicalRouteFamily.partnerDetail,
    routeName: PartnerDetailRoute.name,
    fullPath: '/parceiro/ananda-torres',
    currentPath: '/parceiro/ananda-torres',
    pageRouteInfo: PartnerDetailRoute(slug: 'ananda-torres'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: DiscoveryRoute.name,
  ),
  _PolicyCase(
    description: 'static asset detail',
    family: CanonicalRouteFamily.staticAssetDetail,
    routeName: StaticAssetDetailRoute.name,
    fullPath: '/locais/praia-das-virtudes',
    currentPath: '/locais/praia-das-virtudes',
    pageRouteInfo: StaticAssetDetailRoute(assetRef: 'praia-das-virtudes'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: DiscoveryRoute.name,
  ),
  const _PolicyCase(
    description: 'profile root',
    family: CanonicalRouteFamily.profileRoot,
    routeName: ProfileRoute.name,
    fullPath: '/profile',
    currentPath: '/profile',
    pageRouteInfo: ProfileRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  _PolicyCase(
    description: 'event search',
    family: CanonicalRouteFamily.eventSearch,
    routeName: EventSearchRoute.name,
    fullPath: '/agenda',
    currentPath: '/agenda',
    pageRouteInfo: EventSearchRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: ProfileRoute.name,
  ),
  _PolicyCase(
    description: 'immersive event detail',
    family: CanonicalRouteFamily.immersiveEventDetail,
    routeName: ImmersiveEventDetailRoute.name,
    fullPath: '/agenda/evento/festival-do-mar',
    currentPath: '/agenda/evento/festival-do-mar',
    pageRouteInfo: ImmersiveEventDetailRoute(eventSlug: 'festival-do-mar'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  _PolicyCase(
    description: 'city map',
    family: CanonicalRouteFamily.cityMap,
    routeName: CityMapRoute.name,
    fullPath: '/mapa',
    currentPath: '/mapa',
    pageRouteInfo: CityMapRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  _PolicyCase(
    description: 'poi detail',
    family: CanonicalRouteFamily.poiDetail,
    routeName: PoiDetailsRoute.name,
    fullPath: '/mapa',
    currentPath: '/mapa?poi=pier-9&stack=agenda',
    pageRouteInfo: PoiDetailsRoute(poi: 'pier-9', stack: 'agenda'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: CityMapRoute.name,
    queryParams: <String, dynamic>{
      'poi': 'pier-9',
      'stack': 'agenda',
    },
  ),
  const _PolicyCase(
    description: 'invite flow',
    family: CanonicalRouteFamily.inviteFlow,
    routeName: InviteFlowRoute.name,
    fullPath: '/convites',
    currentPath: '/convites',
    pageRouteInfo: InviteFlowRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  const _PolicyCase(
    description: 'invite entry',
    family: CanonicalRouteFamily.inviteEntry,
    routeName: InviteEntryRoute.name,
    fullPath: '/invite',
    currentPath: '/invite?code=abc123',
    pageRouteInfo: InviteEntryRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
    queryParams: <String, dynamic>{'code': 'abc123'},
  ),
  _PolicyCase(
    description: 'invite share',
    family: CanonicalRouteFamily.inviteShare,
    routeName: InviteShareRoute.name,
    fullPath: '/convites/compartilhar',
    currentPath: '/convites/compartilhar',
    pageRouteInfo: InviteShareRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: InviteFlowRoute.name,
  ),
  _PolicyCase(
    description: 'app promotion with auth-owned redirect',
    family: CanonicalRouteFamily.appPromotion,
    routeName: AppPromotionRoute.name,
    fullPath: '/baixe-o-app',
    currentPath: '/baixe-o-app?redirect=%2Fauth%2Flogin',
    pageRouteInfo: AppPromotionRoute(redirectPath: '/auth/login'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
    queryParams: <String, dynamic>{'redirect': '/auth/login'},
  ),
  _PolicyCase(
    description: 'app promotion with invite redirect',
    family: CanonicalRouteFamily.appPromotion,
    routeName: AppPromotionRoute.name,
    fullPath: '/baixe-o-app',
    currentPath: '/baixe-o-app?redirect=%2Finvite%3Fcode%3Dabc123',
    pageRouteInfo: AppPromotionRoute(redirectPath: '/invite?code=abc123'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: InviteEntryRoute.name,
    queryParams: <String, dynamic>{'redirect': '/invite?code=abc123'},
  ),
  _PolicyCase(
    description: 'auth login',
    family: CanonicalRouteFamily.authLogin,
    routeName: AuthLoginRoute.name,
    fullPath: '/auth/login',
    currentPath: '/auth/login',
    pageRouteInfo: AuthLoginRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  _PolicyCase(
    description: 'recovery password',
    family: CanonicalRouteFamily.recoveryPassword,
    routeName: RecoveryPasswordRoute.name,
    fullPath: '/auth/recovery-password',
    currentPath: '/auth/recovery-password',
    pageRouteInfo: RecoveryPasswordRoute(initialEmmail: 'test@belluga.space'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: AuthLoginRoute.name,
  ),
  const _PolicyCase(
    description: 'auth create new password',
    family: CanonicalRouteFamily.authCreateNewPassword,
    routeName: AuthCreateNewPasswordRoute.name,
    fullPath: '/auth/create-password',
    currentPath: '/auth/create-password',
    pageRouteInfo: AuthCreateNewPasswordRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  const _PolicyCase(
    description: 'landlord home',
    family: CanonicalRouteFamily.landlordHome,
    routeName: LandlordHomeRoute.name,
    fullPath: '/',
    currentPath: '/',
    pageRouteInfo: LandlordHomeRoute(),
    noHistoryBehavior: _NoHistoryBehavior.requestExit,
  ),
  const _PolicyCase(
    description: 'account workspace home',
    family: CanonicalRouteFamily.accountWorkspaceHome,
    routeName: AccountWorkspaceHomeRoute.name,
    fullPath: '/workspace',
    currentPath: '/workspace',
    pageRouteInfo: AccountWorkspaceHomeRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: ProfileRoute.name,
  ),
  _PolicyCase(
    description: 'account workspace scoped',
    family: CanonicalRouteFamily.accountWorkspaceScoped,
    routeName: AccountWorkspaceScopedRoute.name,
    fullPath: '/workspace/account-alpha',
    currentPath: '/workspace/account-alpha',
    pageRouteInfo: AccountWorkspaceScopedRoute(accountSlug: 'account-alpha'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: AccountWorkspaceHomeRoute.name,
  ),
  _PolicyCase(
    description: 'account workspace create event',
    family: CanonicalRouteFamily.accountWorkspaceCreateEvent,
    routeName: AccountWorkspaceCreateEventRoute.name,
    fullPath: '/workspace/account-alpha/eventos/criar',
    currentPath: '/workspace/account-alpha/eventos/criar',
    pageRouteInfo: AccountWorkspaceCreateEventRoute(accountSlug: 'account-alpha'),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: AccountWorkspaceHomeRoute.name,
  ),
  const _PolicyCase(
    description: 'tenant admin dashboard',
    family: CanonicalRouteFamily.tenantAdminDashboard,
    routeName: TenantAdminDashboardRoute.name,
    fullPath: '/admin',
    currentPath: '/admin',
    pageRouteInfo: TenantAdminDashboardRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replaceAll,
    expectedRouteName: TenantHomeRoute.name,
  ),
  const _PolicyCase(
    description: 'tenant admin events root',
    family: CanonicalRouteFamily.tenantAdminEventsRoot,
    routeName: TenantAdminEventsRoute.name,
    fullPath: '/admin/events',
    currentPath: '/admin/events',
    pageRouteInfo: TenantAdminEventsRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replace,
    expectedRouteName: TenantAdminDashboardRoute.name,
  ),
  const _PolicyCase(
    description: 'tenant admin events internal',
    family: CanonicalRouteFamily.tenantAdminEventsInternal,
    routeName: TenantAdminEventCreateRoute.name,
    fullPath: '/admin/events/criar',
    currentPath: '/admin/events/criar',
    pageRouteInfo: TenantAdminEventCreateRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replace,
    expectedRouteName: TenantAdminEventsRoute.name,
  ),
  const _PolicyCase(
    description: 'tenant admin accounts root',
    family: CanonicalRouteFamily.tenantAdminAccountsRoot,
    routeName: TenantAdminAccountsListRoute.name,
    fullPath: '/admin/accounts',
    currentPath: '/admin/accounts',
    pageRouteInfo: TenantAdminAccountsListRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replace,
    expectedRouteName: TenantAdminDashboardRoute.name,
  ),
  _PolicyCase(
    description: 'tenant admin accounts internal',
    family: CanonicalRouteFamily.tenantAdminAccountsInternal,
    routeName: TenantAdminAccountCreateRoute.name,
    fullPath: '/admin/accounts/criar',
    currentPath: '/admin/accounts/criar',
    pageRouteInfo: const TenantAdminAccountCreateRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replace,
    expectedRouteName: TenantAdminAccountsListRoute.name,
  ),
  const _PolicyCase(
    description: 'tenant admin assets root',
    family: CanonicalRouteFamily.tenantAdminAssetsRoot,
    routeName: TenantAdminStaticAssetsListRoute.name,
    fullPath: '/admin/assets',
    currentPath: '/admin/assets',
    pageRouteInfo: TenantAdminStaticAssetsListRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replace,
    expectedRouteName: TenantAdminDashboardRoute.name,
  ),
  const _PolicyCase(
    description: 'tenant admin assets internal',
    family: CanonicalRouteFamily.tenantAdminAssetsInternal,
    routeName: TenantAdminStaticAssetCreateRoute.name,
    fullPath: '/admin/assets/criar',
    currentPath: '/admin/assets/criar',
    pageRouteInfo: TenantAdminStaticAssetCreateRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replace,
    expectedRouteName: TenantAdminStaticAssetsListRoute.name,
  ),
  const _PolicyCase(
    description: 'tenant admin settings root',
    family: CanonicalRouteFamily.tenantAdminSettingsRoot,
    routeName: TenantAdminSettingsRoute.name,
    fullPath: '/admin/settings',
    currentPath: '/admin/settings',
    pageRouteInfo: TenantAdminSettingsRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replace,
    expectedRouteName: TenantAdminDashboardRoute.name,
  ),
  const _PolicyCase(
    description: 'tenant admin settings internal',
    family: CanonicalRouteFamily.tenantAdminSettingsInternal,
    routeName: TenantAdminSettingsVisualIdentityRoute.name,
    fullPath: '/admin/settings/visual-identity',
    currentPath: '/admin/settings/visual-identity',
    pageRouteInfo: TenantAdminSettingsVisualIdentityRoute(),
    noHistoryBehavior: _NoHistoryBehavior.replace,
    expectedRouteName: TenantAdminSettingsRoute.name,
  ),
];

class _RecordingRootStackRouter extends Fake implements RootStackRouter {
  _RecordingRootStackRouter({
    required this.currentPath,
    required this.canPopResult,
  });

  @override
  final String currentPath;

  final bool canPopResult;
  int canPopCallCount = 0;
  int popCallCount = 0;
  PageRouteInfo<dynamic>? replacedRoute;
  final List<List<PageRouteInfo<dynamic>>> replaceAllRoutes =
      <List<PageRouteInfo<dynamic>>>[];

  @override
  Object? get pathState => null;

  @override
  RootStackRouter get root => this;

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
    replaceAllRoutes.add(List<PageRouteInfo<dynamic>>.from(routes));
  }

  @override
  PageRouteInfo<dynamic>? buildPageRoute(
    String? path, {
    bool includePrefixMatches = true,
  }) {
    final uri = Uri.tryParse(path ?? '');
    final normalizedPath = uri?.path ?? path ?? '';
    switch (normalizedPath) {
      case '/':
        return const TenantHomeRoute();
      case '/auth/login':
        return AuthLoginRoute();
      case '/convites':
        return const InviteFlowRoute();
      case '/descobrir':
        return const DiscoveryRoute();
      case '/invite':
        return const InviteEntryRoute();
      case '/mapa':
        return CityMapRoute(
          poi: uri?.queryParameters['poi'],
          stack: uri?.queryParameters['stack'],
        );
      case '/profile':
        return const ProfileRoute();
      case '/workspace':
        return const AccountWorkspaceHomeRoute();
      default:
        return null;
    }
  }
}

class _FakeRouteMatch extends Fake implements RouteMatch {
  _FakeRouteMatch({
    required this.name,
    required this.fullPath,
    required this.meta,
    required this.pageRouteInfo,
    Map<String, dynamic> queryParams = const <String, dynamic>{},
  }) : _queryParams = Parameters(queryParams);

  @override
  final String name;

  @override
  final String fullPath;

  @override
  final Map<String, dynamic> meta;

  final PageRouteInfo<dynamic> pageRouteInfo;
  final Parameters _queryParams;

  @override
  Parameters get queryParams => _queryParams;

  @override
  PageRouteInfo<dynamic> toPageRouteInfo() => pageRouteInfo;
}
