import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/boundary_route_dismissal.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/support/deterministic_route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_spec.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

typedef _CanonicalRouteNoHistoryBuilder = RouteNoHistoryOutcome Function(
  _CanonicalRouteContext context,
  PageRouteInfo<dynamic>? explicitFallbackRoute,
  RouteNoHistoryDelegate? requestExit,
);

final class _CanonicalRouteContext {
  _CanonicalRouteContext._({
    required this.routeData,
    required this.router,
    required this.family,
    required this.chromeMode,
    required this.currentRoute,
  });

  factory _CanonicalRouteContext.fromRouteData({
    required RouteData routeData,
    StackRouter? router,
  }) {
    final effectiveRouter = _resolveCanonicalStackRouter(
      routeData: routeData,
      router: router,
    );
    final classification = _resolveCanonicalRouteClassification(routeData);
    return _CanonicalRouteContext._(
      routeData: routeData,
      router: effectiveRouter,
      family: classification.family,
      chromeMode: classification.chromeMode,
      currentRoute: routeData.route.toPageRouteInfo(),
    );
  }

  final RouteData routeData;
  final StackRouter router;
  final CanonicalRouteFamily family;
  final RouteChromeMode chromeMode;
  final PageRouteInfo<dynamic> currentRoute;

  RootStackRouter get rootRouter => router.root;
  Parameters get params => routeData.params;
  Parameters get queryParams => routeData.queryParams;
  Object? get args => routeData.args;
  String get routeName => routeData.name;

  PageRouteInfo<dynamic>? buildRouteFromPath(String? path) {
    return rootRouter.buildPageRoute(path, includePrefixMatches: false);
  }
}

StackRouter _resolveCanonicalStackRouter({
  required RouteData routeData,
  StackRouter? router,
}) {
  if (router != null) {
    return router;
  }
  final routeRouter = routeData.router;
  if (routeRouter is StackRouter) {
    return routeRouter;
  }
  throw StateError(
    'Canonical route ${routeData.name} is attached to ${routeRouter.runtimeType}, not a StackRouter.',
  );
}

final class _CanonicalRouteDescriptor {
  const _CanonicalRouteDescriptor({
    required this.family,
    required this.surfaceKind,
    required this.buildNoHistoryOutcome,
    this.adminSection,
  });

  final CanonicalRouteFamily family;
  final BackSurfaceKind surfaceKind;
  final _CanonicalRouteNoHistoryBuilder buildNoHistoryOutcome;
  final AdminShellSection? adminSection;

  bool get isAdminDashboardRoot =>
      family == CanonicalRouteFamily.tenantAdminDashboard;

  bool get isAdminSectionRoot => switch (family) {
        CanonicalRouteFamily.tenantAdminEventsRoot ||
        CanonicalRouteFamily.tenantAdminAccountsRoot ||
        CanonicalRouteFamily.tenantAdminAssetsRoot ||
        CanonicalRouteFamily.tenantAdminSettingsRoot =>
          true,
        _ => false,
      };

  bool get isAdminInternal => switch (family) {
        CanonicalRouteFamily.tenantAdminEventsInternal ||
        CanonicalRouteFamily.tenantAdminAccountsInternal ||
        CanonicalRouteFamily.tenantAdminAssetsInternal ||
        CanonicalRouteFamily.tenantAdminSettingsInternal =>
          true,
        _ => false,
      };
}

final class _CanonicalRouteClassification {
  const _CanonicalRouteClassification({
    required this.family,
    required this.chromeMode,
  });

  final CanonicalRouteFamily family;
  final RouteChromeMode chromeMode;
}

_CanonicalRouteClassification _resolveCanonicalRouteClassification(
  RouteData routeData,
) {
  final family = resolveCanonicalRouteFamilyFromMeta(routeData.meta);
  if (family == null) {
    throw StateError(
      'Route ${routeData.name} is missing canonicalRouteMeta(family: ...).',
    );
  }
  final chromeMode = resolveRouteChromeModeFromMeta(routeData.meta) ??
      RouteChromeMode.standard;
  return _CanonicalRouteClassification(
    family: family,
    chromeMode: chromeMode,
  );
}

RouteChromeMode resolveCanonicalRouteChromeMode(RouteData routeData) {
  return _resolveCanonicalRouteClassification(routeData).chromeMode;
}

AdminShellSection? resolveCanonicalAdminShellSection(RouteData routeData) {
  return _descriptors[_resolveCanonicalRouteClassification(routeData).family]
      ?.adminSection;
}

bool isCanonicalAdminDashboardRoot(RouteData routeData) {
  return _descriptors[_resolveCanonicalRouteClassification(routeData).family]
          ?.isAdminDashboardRoot ==
      true;
}

bool isCanonicalAdminSectionRoot(RouteData routeData) {
  return _descriptors[_resolveCanonicalRouteClassification(routeData).family]
          ?.isAdminSectionRoot ==
      true;
}

bool isCanonicalAdminInternal(RouteData routeData) {
  return _descriptors[_resolveCanonicalRouteClassification(routeData).family]
          ?.isAdminInternal ==
      true;
}

RouteBackPolicy buildCanonicalCurrentRouteBackPolicy(
  BuildContext context, {
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
  PageRouteInfo<dynamic>? explicitFallbackRoute,
  RouteNoHistoryDelegate? requestExit,
  String? reentrancyKey,
}) {
  return buildCanonicalRouteBackPolicyForRouteData(
    routeData: RouteData.of(context),
    router: context.router,
    consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
    explicitFallbackRoute: explicitFallbackRoute,
    requestExit: requestExit,
    reentrancyKey: reentrancyKey,
  );
}

RouteBackPolicy buildCanonicalRouteBackPolicyForRouteData({
  required RouteData routeData,
  StackRouter? router,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
  PageRouteInfo<dynamic>? explicitFallbackRoute,
  RouteNoHistoryDelegate? requestExit,
  String? reentrancyKey,
}) {
  final routeContext = _CanonicalRouteContext.fromRouteData(
    routeData: routeData,
    router: router,
  );
  final descriptor = _descriptors[routeContext.family]!;
  return DeterministicRouteBackPolicy(
    routeContext.router,
    spec: RouteBackSpec(
      surfaceKind: descriptor.surfaceKind,
      consumeLocalStateIfNeeded: consumeBackNavigationIfNeeded,
      noHistoryOutcome: descriptor.buildNoHistoryOutcome(
        routeContext,
        explicitFallbackRoute,
        requestExit,
      ),
      reentrancyKey: reentrancyKey ?? routeContext.routeName,
    ),
  );
}

void performCanonicalCurrentRouteBack(
  BuildContext context, {
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
  PageRouteInfo<dynamic>? explicitFallbackRoute,
  RouteNoHistoryDelegate? requestExit,
  String? reentrancyKey,
}) {
  buildCanonicalCurrentRouteBackPolicy(
    context,
    consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
    explicitFallbackRoute: explicitFallbackRoute,
    requestExit: requestExit,
    reentrancyKey: reentrancyKey,
  ).handleBack();
}

final Map<CanonicalRouteFamily, _CanonicalRouteDescriptor> _descriptors =
    <CanonicalRouteFamily, _CanonicalRouteDescriptor>{
  CanonicalRouteFamily.tenantHome: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.tenantHome,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, __, requestExit) => requestExit == null
        ? RouteNoHistoryOutcome.noop()
        : RouteNoHistoryOutcome.requestExit(requestExit),
  ),
  CanonicalRouteFamily.tenantPrivacyPolicy: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.tenantPrivacyPolicy,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.discoveryRoot: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.discoveryRoot,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.partnerDetail: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.partnerDetail,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const DiscoveryRoute(),
    ),
  ),
  CanonicalRouteFamily.staticAssetDetail: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.staticAssetDetail,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const DiscoveryRoute(),
    ),
  ),
  CanonicalRouteFamily.profileRoot: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.profileRoot,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.eventSearch: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.eventSearch,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const ProfileRoute(),
    ),
  ),
  CanonicalRouteFamily.immersiveEventDetail: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.immersiveEventDetail,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.cityMap: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.cityMap,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.poiDetail: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.poiDetail,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? CityMapRoute(),
    ),
  ),
  CanonicalRouteFamily.inviteFlow: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.inviteFlow,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.inviteEntry: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.inviteEntry,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.inviteShare: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.inviteShare,
    surfaceKind: BackSurfaceKind.internalOnly,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const InviteFlowRoute(),
    ),
  ),
  CanonicalRouteFamily.appPromotion: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.appPromotion,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (context, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? _promotionDismissRoute(context),
    ),
  ),
  CanonicalRouteFamily.authLogin: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.authLogin,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.recoveryPassword: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.recoveryPassword,
    surfaceKind: BackSurfaceKind.internalOnly,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? AuthLoginRoute(),
    ),
  ),
  CanonicalRouteFamily.authCreateNewPassword: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.authCreateNewPassword,
    surfaceKind: BackSurfaceKind.internalOnly,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.landlordHome: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.landlordHome,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, __, requestExit) => requestExit == null
        ? RouteNoHistoryOutcome.noop()
        : RouteNoHistoryOutcome.requestExit(requestExit),
  ),
  CanonicalRouteFamily.accountWorkspaceHome: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.accountWorkspaceHome,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const ProfileRoute(),
    ),
  ),
  CanonicalRouteFamily.accountWorkspaceScoped: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.accountWorkspaceScoped,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const AccountWorkspaceHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.accountWorkspaceCreateEvent: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.accountWorkspaceCreateEvent,
    surfaceKind: BackSurfaceKind.internalOnly,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const AccountWorkspaceHomeRoute(),
    ),
  ),
  CanonicalRouteFamily.tenantAdminDashboard: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.tenantAdminDashboard,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (context, _, __) =>
        RouteNoHistoryOutcome.delegateToShell(
      () => context.rootRouter.replaceAll(<PageRouteInfo<dynamic>>[
        _publicRootRoute(),
      ]),
    ),
    adminSection: AdminShellSection.dashboard,
  ),
  CanonicalRouteFamily.tenantAdminEventsRoot: _adminSectionRootDescriptor(
    family: CanonicalRouteFamily.tenantAdminEventsRoot,
    section: AdminShellSection.events,
    sectionRootRoute: const TenantAdminEventsRoute(),
    sectionPath: '/admin/events',
  ),
  CanonicalRouteFamily.tenantAdminEventsInternal: _adminInternalDescriptor(
    family: CanonicalRouteFamily.tenantAdminEventsInternal,
    section: AdminShellSection.events,
    sectionRootRoute: const TenantAdminEventsRoute(),
    sectionPath: '/admin/events',
  ),
  CanonicalRouteFamily.tenantAdminAccountsRoot: _adminSectionRootDescriptor(
    family: CanonicalRouteFamily.tenantAdminAccountsRoot,
    section: AdminShellSection.accounts,
    sectionRootRoute: const TenantAdminAccountsListRoute(),
    sectionPath: '/admin/accounts',
  ),
  CanonicalRouteFamily.tenantAdminAccountsInternal: _adminInternalDescriptor(
    family: CanonicalRouteFamily.tenantAdminAccountsInternal,
    section: AdminShellSection.accounts,
    sectionRootRoute: const TenantAdminAccountsListRoute(),
    sectionPath: '/admin/accounts',
  ),
  CanonicalRouteFamily.tenantAdminAssetsRoot: _adminSectionRootDescriptor(
    family: CanonicalRouteFamily.tenantAdminAssetsRoot,
    section: AdminShellSection.assets,
    sectionRootRoute: const TenantAdminStaticAssetsListRoute(),
    sectionPath: '/admin/assets',
  ),
  CanonicalRouteFamily.tenantAdminAssetsInternal: _adminInternalDescriptor(
    family: CanonicalRouteFamily.tenantAdminAssetsInternal,
    section: AdminShellSection.assets,
    sectionRootRoute: const TenantAdminStaticAssetsListRoute(),
    sectionPath: '/admin/assets',
  ),
  CanonicalRouteFamily.tenantAdminFiltersRoot: _adminSectionRootDescriptor(
    family: CanonicalRouteFamily.tenantAdminFiltersRoot,
    section: AdminShellSection.filters,
    sectionRootRoute: const TenantAdminDiscoveryFiltersRoute(),
    sectionPath: '/admin/filters',
  ),
  CanonicalRouteFamily.tenantAdminFiltersInternal: _adminInternalDescriptor(
    family: CanonicalRouteFamily.tenantAdminFiltersInternal,
    section: AdminShellSection.filters,
    sectionRootRoute: const TenantAdminDiscoveryFiltersRoute(),
    sectionPath: '/admin/filters',
  ),
  CanonicalRouteFamily.tenantAdminSettingsRoot: _adminSectionRootDescriptor(
    family: CanonicalRouteFamily.tenantAdminSettingsRoot,
    section: AdminShellSection.settings,
    sectionRootRoute: const TenantAdminSettingsRoute(),
    sectionPath: '/admin/settings',
  ),
  CanonicalRouteFamily.tenantAdminSettingsInternal: _adminInternalDescriptor(
    family: CanonicalRouteFamily.tenantAdminSettingsInternal,
    section: AdminShellSection.settings,
    sectionRootRoute: const TenantAdminSettingsRoute(),
    sectionPath: '/admin/settings',
  ),
};

_CanonicalRouteDescriptor _adminSectionRootDescriptor({
  required CanonicalRouteFamily family,
  required AdminShellSection section,
  required PageRouteInfo<dynamic> sectionRootRoute,
  required String sectionPath,
}) {
  return _CanonicalRouteDescriptor(
    family: family,
    surfaceKind: BackSurfaceKind.rootOpenable,
    adminSection: section,
    buildNoHistoryOutcome: (context, _, __) =>
        RouteNoHistoryOutcome.delegateToShell(
      () => context.router.replace(const TenantAdminDashboardRoute()),
    ),
  );
}

_CanonicalRouteDescriptor _adminInternalDescriptor({
  required CanonicalRouteFamily family,
  required AdminShellSection section,
  required PageRouteInfo<dynamic> sectionRootRoute,
  required String sectionPath,
}) {
  return _CanonicalRouteDescriptor(
    family: family,
    surfaceKind: BackSurfaceKind.internalOnly,
    adminSection: section,
    buildNoHistoryOutcome: (context, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.replace(
      explicitFallbackRoute ?? sectionRootRoute,
    ),
  );
}

PageRouteInfo<dynamic> _publicRootRoute() {
  if (_isTenantEnvironment()) {
    return const TenantHomeRoute();
  }
  return const LandlordHomeRoute();
}

bool _isTenantEnvironment() {
  final appData =
      GetIt.I.isRegistered<AppData>() ? GetIt.I.get<AppData>() : null;
  if (appData == null) {
    return true;
  }
  return appData.typeValue.value == EnvironmentType.tenant;
}

PageRouteInfo<dynamic> _promotionDismissRoute(_CanonicalRouteContext context) {
  return resolveBoundaryDismissRoute(
    kind: BoundaryDismissKind.appPromotion,
    redirectPath: context.queryParams.optString('redirect'),
    buildRouteFromPath: context.buildRouteFromPath,
  );
}
