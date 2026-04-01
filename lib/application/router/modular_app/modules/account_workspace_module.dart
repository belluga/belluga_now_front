import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/auth_route_guard.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_account_by_slug_route_resolver.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_selected_tenant_repository_contract.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_lookup_domain_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/presentation/tenant_admin/events/controllers/tenant_admin_events_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class AccountWorkspaceModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerRouteResolver<TenantAdminAccount>(
      TenantAdminAccountBySlugRouteResolver.new,
    );
    bootstrapTenantScopeSelection();
    registerLazySingleton(() => TenantAdminEventsController());
  }

  @visibleForTesting
  static void bootstrapTenantScopeSelection({
    AppDataRepositoryContract? appDataRepository,
    TenantAdminSelectedTenantRepositoryContract? selectedTenantRepository,
  }) {
    final resolvedAppDataRepository = appDataRepository ??
        (GetIt.I.isRegistered<AppDataRepositoryContract>()
            ? GetIt.I.get<AppDataRepositoryContract>()
            : null);
    final resolvedTenantRepository = selectedTenantRepository ??
        (GetIt.I.isRegistered<TenantAdminSelectedTenantRepositoryContract>()
            ? GetIt.I.get<TenantAdminSelectedTenantRepositoryContract>()
            : null);

    if (resolvedAppDataRepository == null || resolvedTenantRepository == null) {
      return;
    }

    final appData = resolvedAppDataRepository.appData;
    if (appData.typeValue.value != EnvironmentType.tenant) {
      return;
    }

    final selectedTenant =
        resolvedTenantRepository.selectedTenantDomain?.trim();
    if (selectedTenant != null && selectedTenant.isNotEmpty) {
      return;
    }

    final tenantHost = appData.hostname.trim();
    if (tenantHost.isEmpty) {
      return;
    }

    resolvedTenantRepository.selectTenantDomain(
      TenantLookupDomainValue.fromRaw(tenantHost),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/workspace',
          page: AccountWorkspaceHomeRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
        ),
        AutoRoute(
          path: '/workspace/:accountSlug',
          page: AccountWorkspaceScopedRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
        ),
        AutoRoute(
          path: '/workspace/:accountSlug/events/create',
          page: AccountWorkspaceCreateEventRoute.page,
          guards: [TenantRouteGuard(), AuthRouteGuard()],
        ),
      ];
}
