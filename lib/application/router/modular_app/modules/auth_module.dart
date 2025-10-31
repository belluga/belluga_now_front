import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/controllers/auth_login_controller_contract.dart';
import 'package:belluga_now/domain/controllers/create_password_controller_contract.dart';
import 'package:belluga_now/domain/controllers/remember_password_contract.dart';
import 'package:belluga_now/domain/controllers/recovery_password_token_controller_contract.dart';
import 'package:belluga_now/presentation/screens/auth/create_new_password/controller/create_password_controller.dart';
import 'package:belluga_now/presentation/screens/auth/login/controller/auth_login_controller.dart';
import 'package:belluga_now/presentation/screens/auth/login/controller/remember_password_controller.dart';
import 'package:belluga_now/presentation/screens/auth/recovery_password_bug/controller/recovery_password_token_controller.dart';
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

    if (!GetIt.I.isRegistered<RememberPasswordContract>()) {
      GetIt.I.registerLazySingleton<RememberPasswordContract>(
        () => RememberPasswordController(),
      );
    }

    registerFactory<CreatePasswordControllerContract>(
      () => CreatePasswordController(),
    );

    if (!GetIt.I.isRegistered<AuthRecoveryPasswordControllerContract>()) {
      GetIt.I.registerFactoryParam<AuthRecoveryPasswordControllerContract,
          String?, void>(
        (initialEmail, _) =>
            AuthRecoveryPasswordController(initialEmail: initialEmail),
      );
    }
  }

  @override
  List<AutoRoute> get routes => const [];
}
