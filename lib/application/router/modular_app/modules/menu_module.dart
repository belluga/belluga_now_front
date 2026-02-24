import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_public/menu/screens/menu_screen/controllers/menu_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class MenuModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<MenuScreenController>(
      () => MenuScreenController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/menu',
          page: TenantMenuRoute.page,
        ),
      ];
}
