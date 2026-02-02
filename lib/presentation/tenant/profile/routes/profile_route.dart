import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/profile_module.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'ProfileRoute')
class ProfileRoutePage extends StatelessWidget {
  const ProfileRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<ProfileModule>(
      child: const ProfileScreen(),
    );
  }
}
