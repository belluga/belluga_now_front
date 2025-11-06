import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/auth_module.dart';
import 'package:belluga_now/presentation/common/screens/auth/recovery_password_bug/recovery_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'RecoveryPasswordRoute')
class RecoveryPasswordRoutePage extends StatelessWidget {
  const RecoveryPasswordRoutePage({super.key, this.initialEmmail});

  final String? initialEmmail;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<AuthModule>(
      child: RecoveryPasswordScreen(initialEmmail: initialEmmail),
    );
  }
}
