import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/landlord_route_guard.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_static_asset_detail_route_resolver.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_asset.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_location_picker_controller.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_tenant_scope_service.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/controllers/tenant_admin_organizations_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/profile_types/controllers/tenant_admin_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/settings/controllers/tenant_admin_settings_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/shell/controllers/tenant_admin_shell_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/static_assets/controllers/tenant_admin_static_assets_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/static_profile_types/controllers/tenant_admin_static_profile_types_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/taxonomies/controllers/tenant_admin_taxonomies_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class TenantAdminModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() async {
    _registerResolvers();
    _registerControllersAndServices();
  }

  void _registerResolvers() {
    registerRouteResolver<TenantAdminStaticAsset>(
      TenantAdminStaticAssetDetailRouteResolver.new,
    );
  }

  void _registerControllersAndServices() {
    registerLazySingleton<TenantAdminShellController>(
      () => TenantAdminShellController(),
    );
    registerLazySingleton<TenantAdminAccountsController>(
      () => TenantAdminAccountsController(),
    );
    registerLazySingleton<TenantAdminLocationSelectionContract>(
      () => TenantAdminLocationSelectionService(),
    );
    registerLazySingleton<TenantAdminTenantScopeContract>(
      () => TenantAdminTenantScopeService(),
    );
    registerFactory<TenantAdminLocationPickerController>(
      () => TenantAdminLocationPickerController(),
    );
    registerLazySingleton<TenantAdminAccountProfilesController>(
      () => TenantAdminAccountProfilesController(),
    );
    registerFactory<TenantAdminOrganizationsController>(
      () => TenantAdminOrganizationsController(),
    );
    registerFactory<TenantAdminProfileTypesController>(
      () => TenantAdminProfileTypesController(),
    );
    registerFactory<TenantAdminTaxonomiesController>(
      () => TenantAdminTaxonomiesController(),
    );
    registerFactory<TenantAdminStaticProfileTypesController>(
      () => TenantAdminStaticProfileTypesController(),
    );
    registerFactory<TenantAdminSettingsController>(
      () => TenantAdminSettingsController(),
    );
    registerLazySingleton<TenantAdminStaticAssetsController>(
      () => TenantAdminStaticAssetsController(),
    );
  }

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
              path: 'events',
              page: TenantAdminEventsRoute.page,
            ),
            AutoRoute(
              path: 'accounts',
              page: TenantAdminAccountsListRoute.page,
            ),
            CustomRoute(
              path: 'accounts/create',
              page: TenantAdminAccountCreateRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            CustomRoute(
              path: 'accounts/location-picker',
              page: TenantAdminLocationPickerRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            AutoRoute(
              path: 'accounts/:accountSlug',
              page: TenantAdminAccountDetailRoute.page,
            ),
            CustomRoute(
              path: 'accounts/:accountSlug/profiles/create',
              page: TenantAdminAccountProfileCreateRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            CustomRoute(
              path: 'accounts/:accountSlug/profiles/:accountProfileId/edit',
              page: TenantAdminAccountProfileEditRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            AutoRoute(
              path: 'organizations',
              page: TenantAdminOrganizationsListRoute.page,
            ),
            CustomRoute(
              path: 'organizations/create',
              page: TenantAdminOrganizationCreateRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
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
              path: 'profile-types/:profileType',
              page: TenantAdminProfileTypeDetailRoute.page,
            ),
            CustomRoute(
              path: 'profile-types/create',
              page: TenantAdminProfileTypeCreateRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            CustomRoute(
              path: 'profile-types/:profileType/edit',
              page: TenantAdminProfileTypeEditRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            AutoRoute(
              path: 'static_profile_types',
              page: TenantAdminStaticProfileTypesListRoute.page,
            ),
            AutoRoute(
              path: 'static_profile_types/:profileType',
              page: TenantAdminStaticProfileTypeDetailRoute.page,
            ),
            CustomRoute(
              path: 'static_profile_types/create',
              page: TenantAdminStaticProfileTypeCreateRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            CustomRoute(
              path: 'static_profile_types/:profileType/edit',
              page: TenantAdminStaticProfileTypeEditRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            AutoRoute(
              path: 'taxonomies',
              page: TenantAdminTaxonomiesListRoute.page,
            ),
            CustomRoute(
              path: 'taxonomies/create',
              page: TenantAdminTaxonomyCreateRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            CustomRoute(
              path: 'taxonomies/:taxonomyId/edit',
              page: TenantAdminTaxonomyEditRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            AutoRoute(
              path: 'taxonomies/:taxonomyId/terms',
              page: TenantAdminTaxonomyTermsRoute.page,
            ),
            AutoRoute(
              path: 'taxonomies/:taxonomyId/terms/:termId',
              page: TenantAdminTaxonomyTermDetailRoute.page,
            ),
            CustomRoute(
              path: 'taxonomies/:taxonomyId/terms/create',
              page: TenantAdminTaxonomyTermCreateRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            CustomRoute(
              path: 'taxonomies/:taxonomyId/terms/:termId/edit',
              page: TenantAdminTaxonomyTermEditRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            AutoRoute(
              path: 'static_assets',
              page: TenantAdminStaticAssetsListRoute.page,
            ),
            AutoRoute(
              path: 'static_assets/:assetId',
              page: TenantAdminStaticAssetDetailRoute.page,
            ),
            CustomRoute(
              path: 'static_assets/create',
              page: TenantAdminStaticAssetCreateRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            CustomRoute(
              path: 'static_assets/:assetId/edit',
              page: TenantAdminStaticAssetEditRoute.page,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 260),
              reverseDuration: const Duration(milliseconds: 220),
            ),
            AutoRoute(
              path: 'settings',
              page: TenantAdminSettingsRoute.page,
            ),
          ],
        ),
      ];
}
