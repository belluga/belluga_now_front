import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/tenant_route_guard.dart';
import 'package:belluga_now/presentation/shared/location_permission/controllers/location_permission_controller.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InitializationModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerFactory<LocationPermissionController>(
      () => LocationPermissionController(),
    );

    registerLazySingleton<InitScreenController>(
      () => InitScreenController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: InitRoute.page,
          guards: [TenantRouteGuard()],
        ),
        AutoRoute(
          path: '/location/permission',
          page: LocationPermissionRoute.page,
          guards: [TenantRouteGuard()],
        ),
      ];
}
