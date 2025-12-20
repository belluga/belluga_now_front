import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/landlord_route_guard.dart';
import 'package:belluga_now/presentation/landlord/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class LandlordModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<LandlordHomeScreenController>(
      () => LandlordHomeScreenController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/landlord',
          page: LandlordHomeRoute.page,
          guards: [LandlordRouteGuard()],
        ),
      ];
}
