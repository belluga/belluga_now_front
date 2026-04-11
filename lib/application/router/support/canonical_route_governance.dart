import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_history_state.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/application/router/support/deterministic_route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_spec.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

typedef _CanonicalRouteNoHistoryBuilder = RouteNoHistoryOutcome Function(
  _CanonicalRouteContext context,
  PageRouteInfo<dynamic>? explicitFallbackRoute,
  RouteNoHistoryDelegate? requestExit,
);

typedef _CanonicalRouteHistoryBuilder = List<_CanonicalHistoryStage> Function(
  _CanonicalRouteContext context,
);

final class _CanonicalRouteContext {
  _CanonicalRouteContext._({
    required this.routeData,
    required this.router,
    required this.family,
    required this.chromeMode,
    required this.currentRoute,
    required this.currentPath,
    required this.pathState,
  });

  factory _CanonicalRouteContext.fromRouteData({
    required RouteData routeData,
    StackRouter? router,
    String? currentPath,
    Object? pathState,
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
      currentPath: currentPath ?? effectiveRouter.root.currentPath,
      pathState: pathState ?? (kIsWeb ? effectiveRouter.root.pathState : null),
    );
  }

  final RouteData routeData;
  final StackRouter router;
  final CanonicalRouteFamily family;
  final RouteChromeMode chromeMode;
  final PageRouteInfo<dynamic> currentRoute;
  final String currentPath;
  final Object? pathState;

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

final class _CanonicalHistoryStage {
  const _CanonicalHistoryStage({
    required this.family,
    required this.stageId,
    required this.path,
    required this.routes,
  });

  final CanonicalRouteFamily family;
  final String stageId;
  final String path;
  final List<PageRouteInfo<dynamic>> routes;

  CanonicalRouteHistoryState get historyState {
    return CanonicalRouteHistoryState(
      family: family,
      stageId: stageId,
    );
  }
}

final class _CanonicalRouteDescriptor {
  const _CanonicalRouteDescriptor({
    required this.family,
    required this.surfaceKind,
    required this.buildNoHistoryOutcome,
    required this.buildHistoryStages,
    this.adminSection,
  });

  final CanonicalRouteFamily family;
  final BackSurfaceKind surfaceKind;
  final _CanonicalRouteNoHistoryBuilder buildNoHistoryOutcome;
  final _CanonicalRouteHistoryBuilder buildHistoryStages;
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

final class CanonicalRouteDeepLinkCoordinator extends ChangeNotifier {
  CanonicalRouteDeepLinkCoordinator(
    RootStackRouter router, {
    RouteInformationProvider Function(RootStackRouter router)?
        routeInfoProviderResolver,
    bool Function(RootStackRouter router)? canNavigateBackResolver,
  });

  bool get hasPendingHistorySeed => false;

  void schedulePendingHistorySeedFlush() {}

  bool stageCurrentRouteHistorySeedIfNeeded(
    RouteData routeData, {
    bool notify = false,
  }) {
    return false;
  }

  FutureOr<DeepLink> handlePlatformDeepLink(PlatformDeepLink deepLink) {
    return deepLink;
  }

  void flushPendingHistorySeedIfNeeded() {}
}

final Map<CanonicalRouteFamily, _CanonicalRouteDescriptor> _descriptors =
    <CanonicalRouteFamily, _CanonicalRouteDescriptor>{
  CanonicalRouteFamily.tenantHome: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.tenantHome,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, __, requestExit) => requestExit == null
        ? RouteNoHistoryOutcome.noop()
        : RouteNoHistoryOutcome.requestExit(requestExit),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
    ],
  ),
  CanonicalRouteFamily.tenantPrivacyPolicy: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.tenantPrivacyPolicy,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (_) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.tenantPrivacyPolicy,
        stageId: 'privacy-policy',
        path: '/privacy-policy',
        routes: const <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
          TenantPrivacyPolicyRoute(),
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.discoveryRoot: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.discoveryRoot,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (_) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.discoveryRoot,
        stageId: 'discovery',
        path: '/descobrir',
        routes: const <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
          DiscoveryRoute(),
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.partnerDetail: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.partnerDetail,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const DiscoveryRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _discoveryStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.partnerDetail,
        stageId: 'partner-detail',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          const DiscoveryRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.staticAssetDetail: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.staticAssetDetail,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const DiscoveryRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _discoveryStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.staticAssetDetail,
        stageId: 'static-asset-detail',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          const DiscoveryRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.profileRoot: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.profileRoot,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (_) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.profileRoot,
        stageId: 'profile',
        path: '/profile',
        routes: const <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
          ProfileRoute(),
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.eventSearch: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.eventSearch,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const ProfileRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _profileStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.eventSearch,
        stageId: 'agenda',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          const ProfileRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.immersiveEventDetail: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.immersiveEventDetail,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.immersiveEventDetail,
        stageId: 'event-detail',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.cityMap: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.cityMap,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.cityMap,
        stageId: 'map',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.poiDetail: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.poiDetail,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? CityMapRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.cityMap,
        stageId: 'map',
        path: _mapRootPathFromContext(context),
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          _cityMapRouteFromContext(context),
        ],
      ),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.poiDetail,
        stageId: 'poi-detail',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          _cityMapRouteFromContext(context),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.inviteFlow: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.inviteFlow,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (_) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.inviteFlow,
        stageId: 'invite-flow',
        path: '/convites',
        routes: const <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
          InviteFlowRoute(),
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.inviteEntry: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.inviteEntry,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.inviteEntry,
        stageId: 'invite-entry',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.inviteShare: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.inviteShare,
    surfaceKind: BackSurfaceKind.internalOnly,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const InviteFlowRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      const _CanonicalHistoryStage(
        family: CanonicalRouteFamily.inviteFlow,
        stageId: 'invite-flow',
        path: '/convites',
        routes: <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
          InviteFlowRoute(),
        ],
      ),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.inviteShare,
        stageId: 'invite-share',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          const InviteFlowRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.appPromotion: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.appPromotion,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (context, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? _promotionDismissRoute(context),
    ),
    buildHistoryStages: (context) => _buildPromotionStages(context),
  ),
  CanonicalRouteFamily.authLogin: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.authLogin,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.authLogin,
        stageId: 'auth-login',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.recoveryPassword: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.recoveryPassword,
    surfaceKind: BackSurfaceKind.internalOnly,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? AuthLoginRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.authLogin,
        stageId: 'auth-login',
        path: '/auth/login',
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          AuthLoginRoute(),
        ],
      ),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.recoveryPassword,
        stageId: 'auth-recovery',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          AuthLoginRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.authCreateNewPassword: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.authCreateNewPassword,
    surfaceKind: BackSurfaceKind.internalOnly,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const TenantHomeRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.authCreateNewPassword,
        stageId: 'auth-create-password',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.landlordHome: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.landlordHome,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, __, requestExit) => requestExit == null
        ? RouteNoHistoryOutcome.noop()
        : RouteNoHistoryOutcome.requestExit(requestExit),
    buildHistoryStages: (_) => <_CanonicalHistoryStage>[
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.landlordHome,
        stageId: 'landlord-home',
        path: '/',
        routes: const <PageRouteInfo<dynamic>>[
          LandlordHomeRoute(),
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.accountWorkspaceHome: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.accountWorkspaceHome,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const ProfileRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _profileStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.accountWorkspaceHome,
        stageId: 'workspace-home',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          const ProfileRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.accountWorkspaceScoped: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.accountWorkspaceScoped,
    surfaceKind: BackSurfaceKind.rootOpenable,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const AccountWorkspaceHomeRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _profileStage(),
      const _CanonicalHistoryStage(
        family: CanonicalRouteFamily.accountWorkspaceHome,
        stageId: 'workspace-home',
        path: '/workspace',
        routes: <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
          ProfileRoute(),
          AccountWorkspaceHomeRoute(),
        ],
      ),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.accountWorkspaceScoped,
        stageId: 'workspace-scoped',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          const ProfileRoute(),
          const AccountWorkspaceHomeRoute(),
          context.currentRoute,
        ],
      ),
    ],
  ),
  CanonicalRouteFamily.accountWorkspaceCreateEvent: _CanonicalRouteDescriptor(
    family: CanonicalRouteFamily.accountWorkspaceCreateEvent,
    surfaceKind: BackSurfaceKind.internalOnly,
    buildNoHistoryOutcome: (_, explicitFallbackRoute, __) =>
        RouteNoHistoryOutcome.fallback(
      explicitFallbackRoute ?? const AccountWorkspaceHomeRoute(),
    ),
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _tenantHomeStage(),
      _profileStage(),
      const _CanonicalHistoryStage(
        family: CanonicalRouteFamily.accountWorkspaceHome,
        stageId: 'workspace-home',
        path: '/workspace',
        routes: <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
          ProfileRoute(),
          AccountWorkspaceHomeRoute(),
        ],
      ),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.accountWorkspaceScoped,
        stageId: 'workspace-scoped',
        path: _accountWorkspaceScopedPath(context),
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          const ProfileRoute(),
          const AccountWorkspaceHomeRoute(),
          _accountWorkspaceScopedRoute(context),
        ],
      ),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.accountWorkspaceCreateEvent,
        stageId: 'workspace-create-event',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          const ProfileRoute(),
          const AccountWorkspaceHomeRoute(),
          _accountWorkspaceScopedRoute(context),
          context.currentRoute,
        ],
      ),
    ],
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
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _publicRootStage(),
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.tenantAdminDashboard,
        stageId: 'tenant-admin-dashboard',
        path: '/admin',
        routes: <PageRouteInfo<dynamic>>[
          _publicRootRoute(),
          const TenantAdminShellRoute(
            children: <PageRouteInfo<dynamic>>[
              TenantAdminDashboardRoute(),
            ],
          ),
        ],
      ),
    ],
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
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _publicRootStage(),
      _tenantAdminDashboardStage(),
      _CanonicalHistoryStage(
        family: family,
        stageId: '${section.name}-root',
        path: sectionPath,
        routes: <PageRouteInfo<dynamic>>[
          _publicRootRoute(),
          TenantAdminShellRoute(
            children: <PageRouteInfo<dynamic>>[
              const TenantAdminDashboardRoute(),
              sectionRootRoute,
            ],
          ),
        ],
      ),
    ],
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
    buildHistoryStages: (context) => <_CanonicalHistoryStage>[
      _publicRootStage(),
      _tenantAdminDashboardStage(),
      _CanonicalHistoryStage(
        family: _adminRootFamilyForSection(section),
        stageId: '${section.name}-root',
        path: sectionPath,
        routes: <PageRouteInfo<dynamic>>[
          _publicRootRoute(),
          TenantAdminShellRoute(
            children: <PageRouteInfo<dynamic>>[
              const TenantAdminDashboardRoute(),
              sectionRootRoute,
            ],
          ),
        ],
      ),
      _CanonicalHistoryStage(
        family: family,
        stageId: '${section.name}-internal',
        path: context.currentPath,
        routes: <PageRouteInfo<dynamic>>[
          _publicRootRoute(),
          TenantAdminShellRoute(
            children: <PageRouteInfo<dynamic>>[
              const TenantAdminDashboardRoute(),
              sectionRootRoute,
              context.currentRoute,
            ],
          ),
        ],
      ),
    ],
  );
}

CanonicalRouteFamily _adminRootFamilyForSection(AdminShellSection section) {
  return switch (section) {
    AdminShellSection.dashboard => CanonicalRouteFamily.tenantAdminDashboard,
    AdminShellSection.events => CanonicalRouteFamily.tenantAdminEventsRoot,
    AdminShellSection.accounts => CanonicalRouteFamily.tenantAdminAccountsRoot,
    AdminShellSection.assets => CanonicalRouteFamily.tenantAdminAssetsRoot,
    AdminShellSection.settings => CanonicalRouteFamily.tenantAdminSettingsRoot,
  };
}

_CanonicalHistoryStage _tenantHomeStage() {
  return const _CanonicalHistoryStage(
    family: CanonicalRouteFamily.tenantHome,
    stageId: 'tenant-home',
    path: '/',
    routes: <PageRouteInfo<dynamic>>[
      TenantHomeRoute(),
    ],
  );
}

_CanonicalHistoryStage _discoveryStage() {
  return const _CanonicalHistoryStage(
    family: CanonicalRouteFamily.discoveryRoot,
    stageId: 'discovery',
    path: '/descobrir',
    routes: <PageRouteInfo<dynamic>>[
      TenantHomeRoute(),
      DiscoveryRoute(),
    ],
  );
}

_CanonicalHistoryStage _profileStage() {
  return const _CanonicalHistoryStage(
    family: CanonicalRouteFamily.profileRoot,
    stageId: 'profile',
    path: '/profile',
    routes: <PageRouteInfo<dynamic>>[
      TenantHomeRoute(),
      ProfileRoute(),
    ],
  );
}

_CanonicalHistoryStage _publicRootStage() {
  return _CanonicalHistoryStage(
    family: _isTenantEnvironment()
        ? CanonicalRouteFamily.tenantHome
        : CanonicalRouteFamily.landlordHome,
    stageId: 'public-root',
    path: '/',
    routes: <PageRouteInfo<dynamic>>[
      _publicRootRoute(),
    ],
  );
}

_CanonicalHistoryStage _tenantAdminDashboardStage() {
  return _CanonicalHistoryStage(
    family: CanonicalRouteFamily.tenantAdminDashboard,
    stageId: 'tenant-admin-dashboard',
    path: '/admin',
    routes: <PageRouteInfo<dynamic>>[
      _publicRootRoute(),
      const TenantAdminShellRoute(
        children: <PageRouteInfo<dynamic>>[
          TenantAdminDashboardRoute(),
        ],
      ),
    ],
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

String _mapRootPathFromContext(_CanonicalRouteContext context) {
  final uri = Uri.parse(context.currentPath);
  return uri.replace(path: '/mapa').toString();
}

CityMapRoute _cityMapRouteFromContext(_CanonicalRouteContext context) {
  return CityMapRoute(
    poi: context.queryParams.optString('poi'),
    stack: context.queryParams.optString('stack'),
  );
}

PageRouteInfo<dynamic> _promotionDismissRoute(_CanonicalRouteContext context) {
  final redirectPath = context.queryParams.optString('redirect');
  final dismissPath = resolveWebPromotionDismissPath(
    redirectPath: redirectPath ?? '/',
  );
  return context.buildRouteFromPath(dismissPath) ?? const TenantHomeRoute();
}

List<_CanonicalHistoryStage> _buildPromotionStages(
    _CanonicalRouteContext context) {
  final redirectPath = context.queryParams.optString('redirect');
  final dismissPath = resolveWebPromotionDismissPath(
    redirectPath: redirectPath ?? '/',
  );
  final stages = <_CanonicalHistoryStage>[
    _tenantHomeStage(),
  ];
  if (dismissPath.startsWith('/invite')) {
    stages.add(
      _CanonicalHistoryStage(
        family: CanonicalRouteFamily.inviteEntry,
        stageId: 'invite-entry',
        path: dismissPath,
        routes: <PageRouteInfo<dynamic>>[
          const TenantHomeRoute(),
          context.buildRouteFromPath(dismissPath) ?? const InviteEntryRoute(),
        ],
      ),
    );
  }
  stages.add(
    _CanonicalHistoryStage(
      family: CanonicalRouteFamily.appPromotion,
      stageId: 'app-promotion',
      path: context.currentPath,
      routes: <PageRouteInfo<dynamic>>[
        if (stages.length == 1) ...const <PageRouteInfo<dynamic>>[
          TenantHomeRoute(),
        ] else
          ...stages.last.routes,
        context.currentRoute,
      ],
    ),
  );
  return stages;
}

AccountWorkspaceScopedRoute _accountWorkspaceScopedRoute(
  _CanonicalRouteContext context,
) {
  return AccountWorkspaceScopedRoute(
    accountSlug: context.params.getString('accountSlug'),
  );
}

String _accountWorkspaceScopedPath(_CanonicalRouteContext context) {
  return '/workspace/${Uri.encodeComponent(context.params.getString('accountSlug'))}';
}
