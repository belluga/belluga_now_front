import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/resolvers/account_profile_detail_route_resolver.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/services/partner_profile_config_builder.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/partners/controllers/account_profile_detail_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class DiscoveryModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton(() => DiscoveryScreenController());
    registerLazySingleton<PartnerProfileConfigBuilder>(
      () => PartnerProfileConfigBuilder(),
    );
    registerFactory(() => AccountProfileDetailController());
    registerRouteResolver<AccountProfileModel>(
      AccountProfileDetailRouteResolver.new,
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/descobrir',
          page: DiscoveryRoute.page,
        ),
        AutoRoute(
          path: '/parceiro/:slug',
          page: PartnerDetailRoute.page,
        ),
      ];
}
