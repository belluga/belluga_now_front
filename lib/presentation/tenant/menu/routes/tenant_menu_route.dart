import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant/menu/screens/menu_screen/menu_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantMenuRoute')
class TenantMenuRoutePage extends StatelessWidget {
  const TenantMenuRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MenuScreen();
  }
}
