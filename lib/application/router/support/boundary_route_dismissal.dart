import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/route_redirect_path.dart';

typedef BoundaryDismissRouteBuilder = PageRouteInfo<dynamic>? Function(
  String? path,
);

enum BoundaryDismissKind {
  locationPermission,
  appPromotion,
}

bool hasBoundaryDismissHistory(StackRouter router) {
  if (router.canPop()) {
    return true;
  }

  try {
    return router.root.navigationHistory.canNavigateBack;
  } catch (_) {
    return false;
  }
}

PageRouteInfo<dynamic> resolveBoundaryDismissRoute({
  required BoundaryDismissKind kind,
  String? redirectPath,
  BoundaryDismissRouteBuilder? buildRouteFromPath,
}) {
  final dismissPath = switch (kind) {
    BoundaryDismissKind.locationPermission =>
      resolveLocationPermissionDismissPath(
        redirectPath: redirectPath,
      ),
    BoundaryDismissKind.appPromotion => resolveWebPromotionDismissPath(
        redirectPath: redirectPath ?? '/',
      ),
  };

  return buildRouteFromPath?.call(dismissPath) ?? const TenantHomeRoute();
}

Future<void> replaceAllWithBoundaryDismissRoute({
  required StackRouter router,
  required BoundaryDismissKind kind,
  String? redirectPath,
}) {
  final route = resolveBoundaryDismissRoute(
    kind: kind,
    redirectPath: redirectPath,
    buildRouteFromPath: (path) => router.root.buildPageRoute(
      path,
      includePrefixMatches: false,
    ),
  );
  return router.replaceAll(<PageRouteInfo<dynamic>>[route]);
}

void resolveGuardedBoundaryCancellation({
  required NavigationResolver resolver,
  required StackRouter router,
  required BoundaryDismissKind kind,
  String? redirectPath,
}) {
  resolver.next(false);
  if (hasBoundaryDismissHistory(router)) {
    return;
  }

  unawaited(
    Future<void>.microtask(
      () => replaceAllWithBoundaryDismissRoute(
        router: router,
        kind: kind,
        redirectPath: redirectPath,
      ),
    ),
  );
}

String resolveLocationPermissionDismissPath({
  String? redirectPath,
}) {
  final _ = redirectPath;
  return '/';
}
