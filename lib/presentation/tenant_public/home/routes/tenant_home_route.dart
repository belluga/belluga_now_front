import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/home_module.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/tenant_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantHomeRoute')
class TenantHomeRoutePage extends StatelessWidget {
  const TenantHomeRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<HomeModule>(
      child: const TenantHomeScreen(),
    );
  }
}
