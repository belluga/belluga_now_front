import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/support/canonical_route_governance.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_spec.dart';
import 'package:flutter/widgets.dart';

RouteBackPolicy buildTenantAdminCurrentRouteBackPolicy(
  BuildContext context, {
  PageRouteInfo<dynamic>? fallbackRoute,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
}) {
  return buildCanonicalCurrentRouteBackPolicy(
    context,
    explicitFallbackRoute: fallbackRoute,
    consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
  );
}

void performTenantAdminCurrentRouteBack(
  BuildContext context, {
  PageRouteInfo<dynamic>? fallbackRoute,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
}) {
  performCanonicalCurrentRouteBack(
    context,
    explicitFallbackRoute: fallbackRoute,
    consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
  );
}
