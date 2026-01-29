import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/landlord_route_guard.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class TenantAdminModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() async {}

  @override
  List<AutoRoute> get routes => [
      AutoRoute(
          path: '/admin',
          page: TenantAdminShellRoute.page,
          guards: [LandlordRouteGuard()],
          children: [
            AutoRoute(
              path: '',
              page: TenantAdminDashboardRoute.page,
              initial: true,
            ),
            AutoRoute(
              path: 'accounts',
              page: TenantAdminAccountsListRoute.page,
            ),
            AutoRoute(
              path: 'accounts/create',
              page: TenantAdminAccountCreateRoute.page,
            ),
            AutoRoute(
              path: 'accounts/:accountSlug',
              page: TenantAdminAccountDetailRoute.page,
            ),
            AutoRoute(
              path: 'accounts/:accountSlug/profiles',
              page: TenantAdminAccountProfilesListRoute.page,
            ),
            AutoRoute(
              path: 'accounts/:accountSlug/profiles/create',
              page: TenantAdminAccountProfileCreateRoute.page,
            ),
            AutoRoute(
              path: 'profiles/:accountProfileId',
              page: TenantAdminAccountProfileDetailRoute.page,
            ),
            AutoRoute(
              path: 'organizations',
              page: TenantAdminOrganizationsListRoute.page,
            ),
            AutoRoute(
              path: 'organizations/create',
              page: TenantAdminOrganizationCreateRoute.page,
            ),
            AutoRoute(
              path: 'organizations/:organizationId',
              page: TenantAdminOrganizationDetailRoute.page,
            ),
            AutoRoute(
              path: 'profile-types',
              page: TenantAdminProfileTypesListRoute.page,
            ),
            AutoRoute(
              path: 'profile-types/create',
              page: TenantAdminProfileTypeCreateRoute.page,
            ),
            AutoRoute(
              path: 'profile-types/:profileType/edit',
              page: TenantAdminProfileTypeEditRoute.page,
            ),
          ],
        ),
      ];
}
