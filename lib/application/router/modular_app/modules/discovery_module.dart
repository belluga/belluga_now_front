import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/application/router/resolvers/account_profile_detail_route_resolver.dart';
import 'package:belluga_now/application/router/resolvers/static_asset_detail_route_resolver.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_public/static_assets/controllers/static_asset_detail_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class DiscoveryModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerFactory(() => DiscoveryScreenController());
    registerLazySingleton<PartnerProfileConfigBuilder>(
      () => PartnerProfileConfigBuilder(),
    );
    registerFactory(() => AccountProfileDetailController());
    registerFactory(() => StaticAssetDetailController());
    registerRouteResolver<AccountProfileModel>(
      AccountProfileDetailRouteResolver.new,
    );
    registerRouteResolver<PublicStaticAssetModel>(
      StaticAssetDetailRouteResolver.new,
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/descobrir',
          page: DiscoveryRoute.page,
          guards: [TenantRouteGuard()],
        ),
        AutoRoute(
          path: '/parceiro/:slug',
          page: PartnerDetailRoute.page,
          guards: [TenantRouteGuard()],
        ),
        AutoRoute(
          path: '/static/:assetRef',
          page: StaticAssetDetailRoute.page,
          guards: [TenantRouteGuard()],
        ),
      ];
}
