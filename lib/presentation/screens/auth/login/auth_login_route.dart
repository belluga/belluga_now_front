import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/presentation/screens/auth/login/auth_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'AuthLoginRoute')
class AuthLoginRoutePage extends StatelessWidget {
  const AuthLoginRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleScope<AuthModule>(
      child: AuthLoginScreen(),
    );
  }
}
