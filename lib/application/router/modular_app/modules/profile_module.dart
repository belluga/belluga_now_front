import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/landlord/auth/controllers/landlord_login_controller.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/controllers/profile_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class ProfileModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    if (!GetIt.I.isRegistered<LandlordLoginController>()) {
      registerFactory<LandlordLoginController>(
        () => LandlordLoginController(),
      );
    }
    registerLazySingleton(() => ProfileScreenController());
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/profile',
          page: ProfileRoute.page,
        ),
      ];
}
