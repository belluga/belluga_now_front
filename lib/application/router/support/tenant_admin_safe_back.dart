import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/back_surface_kind.dart';
import 'package:belluga_now/application/router/support/deterministic_route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_policy.dart';
import 'package:belluga_now/application/router/support/route_back_spec.dart';
import 'package:belluga_now/application/router/support/route_no_history_outcome.dart';
import 'package:flutter/widgets.dart';

const Set<String> tenantAdminEventsRouteNames = {
  TenantAdminEventsRoute.name,
  TenantAdminEventCreateRoute.name,
  TenantAdminEventEditRoute.name,
  TenantAdminEventTypesRoute.name,
  TenantAdminEventTypeCreateRoute.name,
  TenantAdminEventTypeEditRoute.name,
};

const Set<String> tenantAdminAccountsRouteNames = {
  TenantAdminAccountsListRoute.name,
  TenantAdminAccountCreateRoute.name,
  TenantAdminAccountDetailRoute.name,
  TenantAdminAccountProfileCreateRoute.name,
  TenantAdminAccountProfileEditRoute.name,
  TenantAdminOrganizationsListRoute.name,
  TenantAdminOrganizationCreateRoute.name,
  TenantAdminOrganizationDetailRoute.name,
  TenantAdminProfileTypesListRoute.name,
  TenantAdminProfileTypeDetailRoute.name,
  TenantAdminProfileTypeCreateRoute.name,
  TenantAdminProfileTypeEditRoute.name,
  TenantAdminLocationPickerRoute.name,
};

const Set<String> tenantAdminAssetsRouteNames = {
  TenantAdminStaticAssetsListRoute.name,
  TenantAdminStaticAssetDetailRoute.name,
  TenantAdminStaticAssetCreateRoute.name,
  TenantAdminStaticAssetEditRoute.name,
  TenantAdminStaticProfileTypesListRoute.name,
  TenantAdminStaticProfileTypeDetailRoute.name,
  TenantAdminStaticProfileTypeCreateRoute.name,
  TenantAdminStaticProfileTypeEditRoute.name,
  TenantAdminTaxonomiesListRoute.name,
  TenantAdminTaxonomyCreateRoute.name,
  TenantAdminTaxonomyEditRoute.name,
  TenantAdminTaxonomyTermsRoute.name,
  TenantAdminTaxonomyTermDetailRoute.name,
  TenantAdminTaxonomyTermCreateRoute.name,
  TenantAdminTaxonomyTermEditRoute.name,
};

const Set<String> tenantAdminSettingsRouteNames = {
  TenantAdminSettingsRoute.name,
  TenantAdminSettingsLocalPreferencesRoute.name,
  TenantAdminSettingsVisualIdentityRoute.name,
  TenantAdminSettingsTechnicalIntegrationsRoute.name,
  TenantAdminSettingsEnvironmentSnapshotRoute.name,
};

const Set<String> tenantAdminSectionRootRouteNames = {
  TenantAdminDashboardRoute.name,
  TenantAdminEventsRoute.name,
  TenantAdminAccountsListRoute.name,
  TenantAdminStaticAssetsListRoute.name,
  TenantAdminSettingsRoute.name,
};

RouteBackPolicy buildTenantAdminCurrentRouteBackPolicy(
  BuildContext context, {
  PageRouteInfo<dynamic>? fallbackRoute,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
}) {
  final routeData = context.topRoute;
  return buildTenantAdminSafeBackPolicy(
    context.router,
    routeName: routeData.name,
    routeArgs: routeData.args,
    fallbackRoute: fallbackRoute,
    reentrancyKey: routeData.name,
    consumeBackNavigationIfNeeded: consumeBackNavigationIfNeeded,
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

RouteBackPolicy buildTenantAdminSafeBackPolicy(
  StackRouter router, {
  required String? routeName,
  Object? routeArgs,
  PageRouteInfo<dynamic>? fallbackRoute,
  String? reentrancyKey,
  RouteBackLocalStateConsumer? consumeBackNavigationIfNeeded,
}) {
  return DeterministicRouteBackPolicy(
    router,
    spec: RouteBackSpec(
      surfaceKind: BackSurfaceKind.internalOnly,
      consumeLocalStateIfNeeded: consumeBackNavigationIfNeeded,
      noHistoryOutcome: RouteNoHistoryOutcome.replace(
        resolveTenantAdminBackFallbackRoute(
          routeName: routeName,
          routeArgs: routeArgs,
          fallbackRoute: fallbackRoute,
        ),
      ),
      reentrancyKey: reentrancyKey ?? routeName,
    ),
  );
}

bool shouldUseTenantAdminSafeBackForRoute(String? routeName) {
  if (routeName == null || routeName == TenantAdminShellRoute.name) {
    return false;
  }
  return !tenantAdminSectionRootRouteNames.contains(routeName);
}

PageRouteInfo<dynamic> resolveTenantAdminBackFallbackRoute({
  required String? routeName,
  Object? routeArgs,
  PageRouteInfo<dynamic>? fallbackRoute,
}) {
  if (fallbackRoute != null) {
    return fallbackRoute;
  }

  if (routeArgs is TenantAdminLocationPickerRouteArgs &&
      routeArgs.backFallbackRoute != null) {
    return routeArgs.backFallbackRoute!;
  }

  return resolveTenantAdminSectionRootRoute(routeName);
}

PageRouteInfo<dynamic> resolveTenantAdminSectionRootRoute(String? routeName) {
  if (routeName == TenantAdminDashboardRoute.name) {
    return const TenantAdminDashboardRoute();
  }
  if (tenantAdminEventsRouteNames.contains(routeName)) {
    return const TenantAdminEventsRoute();
  }
  if (tenantAdminAccountsRouteNames.contains(routeName)) {
    return const TenantAdminAccountsListRoute();
  }
  if (tenantAdminAssetsRouteNames.contains(routeName)) {
    return const TenantAdminStaticAssetsListRoute();
  }
  if (tenantAdminSettingsRouteNames.contains(routeName)) {
    return const TenantAdminSettingsRoute();
  }
  return const TenantAdminDashboardRoute();
}
