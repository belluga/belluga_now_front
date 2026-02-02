import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_create_new_password_screen/auth_create_new_password.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'AuthCreateNewPasswordRoute')
class AuthCreateNewPasswordRoutePage extends StatelessWidget {
  const AuthCreateNewPasswordRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<AuthModule>(
      child: const AuthCreateNewPasswordScreen(),
    );
  }
}
