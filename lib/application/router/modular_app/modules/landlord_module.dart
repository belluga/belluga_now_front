import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/guards/landlord_route_guard.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/presentation/landlord_area/auth/controllers/landlord_home_login_controller.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_login_sheet_controller.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class LandlordModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    if (!GetIt.I.isRegistered<LandlordHomeLoginController>()) {
      registerLazySingleton<LandlordHomeLoginController>(
        () => LandlordHomeLoginController(),
      );
    }
    if (!GetIt.I.isRegistered<LandlordHomeLoginSheetController>()) {
      registerLazySingleton<LandlordHomeLoginSheetController>(
        () => LandlordHomeLoginSheetController(),
      );
    }

    registerLazySingleton<LandlordHomeScreenController>(
      () => LandlordHomeScreenController(),
    );
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: LandlordHomeRoute.page,
          guards: [LandlordRouteGuard()],
          meta: canonicalRouteMeta(family: CanonicalRouteFamily.landlordHome),
        ),
        RedirectRoute(
          path: '/landlord',
          redirectTo: '/admin',
        ),
      ];
}
