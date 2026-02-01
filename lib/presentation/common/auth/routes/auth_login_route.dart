import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/auth_login_screen.dart';
import 'package:belluga_now/presentation/landlord/auth/controllers/landlord_login_controller.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'AuthLoginRoute')
class AuthLoginRoutePage extends StatelessWidget {
  const AuthLoginRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<AuthModule>(
      child: Builder(
        builder: (context) {
          return AuthLoginScreen(
            controller: GetIt.I.get<AuthLoginControllerContract>(),
            landlordLoginController: GetIt.I.get<LandlordLoginController>(),
            appData: GetIt.I.get<AppData>(),
          );
        },
      ),
    );
  }
}
