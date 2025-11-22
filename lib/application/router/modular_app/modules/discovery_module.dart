import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/partners/controllers/partner_detail_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class DiscoveryModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton(() => DiscoveryScreenController());
    registerFactory(() => PartnerDetailController());
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
