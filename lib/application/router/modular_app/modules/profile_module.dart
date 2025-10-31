import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant/screens/profile/controller/profile_screen_controller.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class ProfileModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    registerLazySingleton(() => ProfileScreenController());
  }

  @override
  List<AutoRoute> get routes => const [];
}
