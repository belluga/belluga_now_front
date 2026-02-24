import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/menu_module.dart';
import 'package:belluga_now/presentation/tenant_public/menu/screens/menu_screen/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantMenuRoute')
class TenantMenuRoutePage extends StatelessWidget {
  const TenantMenuRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleScope<MenuModule>(
      child: MenuScreen(),
    );
  }
}
