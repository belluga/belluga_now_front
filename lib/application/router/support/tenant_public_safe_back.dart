import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/deterministic_route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_spec.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome.dart';

void performTenantPublicSafeBack(
  StackRouter router, {
  required PageRouteInfo<dynamic> fallbackRoute,
  String? reentrancyKey,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
}) {
  buildTenantPublicSafeBackPolicy(
    router,
    fallbackRoute: fallbackRoute,
    reentrancyKey: reentrancyKey,
    consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
  ).handleBack();
}

RouteBackPolicy buildTenantPublicSafeBackPolicy(
  StackRouter router, {
  required PageRouteInfo<dynamic> fallbackRoute,
  String? reentrancyKey,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
}) {
  return DeterministicRouteBackPolicy(
    router,
    spec: RouteBackSpec(
      surfaceKind: BackSurfaceKind.rootOpenable,
      consumeLocalStateIfNeeded: consumeBackNavigationIfNeeded,
      noHistoryOutcome: RouteNoHistoryOutcome.fallback(fallbackRoute),
      reentrancyKey: reentrancyKey,
    ),
  );
}
