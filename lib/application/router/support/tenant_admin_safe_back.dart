import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/deterministic_route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_spec.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome.dart';
import 'package:flutter/widgets.dart';

RouteBackPolicy buildTenantAdminCurrentRouteBackPolicy(
  BuildContext context, {
  PageRouteInfo<dynamic>? fallbackRoute,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
}) {
  final routeDataScope = context.findAncestorWidgetOfExactType<RouteDataScope>();
  if (routeDataScope != null) {
    return buildCanonicalRouteBackPolicyForRouteData(
      routeData: routeDataScope.routeData,
      router: context.router,
      explicitFallbackRoute: fallbackRoute,
      consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
    );
  }

  final routerScope = StackRouterScope.of(context, watch: false);
  final router = routerScope?.controller;
  if (router == null) {
    return _TenantAdminCompatLocalBackPolicy(
      consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
    );
  }

  // Some widget tests still mount tenant-admin screens outside AutoRoutePage.
  // Keep runtime semantics canonical, but allow those harnesses to build until
  // they are migrated to RouteDataScope-aware wrappers.
  return DeterministicRouteBackPolicy(
    router,
    spec: RouteBackSpec(
      surfaceKind: BackSurfaceKind.internalOnly,
      consumeLocalStateIfNeeded: consumeBackNavigationIfNeeded,
      noHistoryOutcome: RouteNoHistoryOutcome.fallback(
        fallbackRoute ?? const TenantAdminDashboardRoute(),
      ),
      reentrancyKey: 'tenant-admin-safe-back-compat',
    ),
  );
}

void performTenantAdminCurrentRouteBack(
  BuildContext context, {
  PageRouteInfo<dynamic>? fallbackRoute,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
}) {
  buildTenantAdminCurrentRouteBackPolicy(
    context,
    fallbackRoute: fallbackRoute,
    consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
  ).handleBack();
}

final class _TenantAdminCompatLocalBackPolicy implements RouteBackPolicy {
  const _TenantAdminCompatLocalBackPolicy({
    this.consumeBackNavigationIfNeeded,
  });

  final RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded;

  @override
  BackSurfaceKind get surfaceKind => BackSurfaceKind.internalOnly;

  @override
  void handleBack() {
    final consumer = consumeBackNavigationIfNeeded;
    if (consumer != null) {
      consumer();
    }
  }
}
