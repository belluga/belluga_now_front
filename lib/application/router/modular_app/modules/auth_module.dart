import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/controllers/auth_login_controller_contract.dart';
import 'package:belluga_now/presentation/screens/auth/login/controller/auth_login_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

class AuthModule extends ModuleContract {
  @override
  FutureOr<void> registerDependencies() {
    if (!GetIt.I.isRegistered<AuthLoginControllerContract>()) {
      GetIt.I.registerLazySingleton<AuthLoginControllerContract>(
        () => AuthLoginController(),
      );
    }
  }

  @override
  List<AutoRoute> get routes => const [];
}
