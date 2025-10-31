import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/landlord/screens/home/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/home/controllers/tenant_home_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class InitializationModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton<TenantHomeScreenController>(
      () => TenantHomeScreenController(),
    );
    registerLazySingleton<LandlordHomeScreenController>(
      () => LandlordHomeScreenController(),
    );
  }

  @override
  List<AutoRoute> get routes => const [];
}
