import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/mercado_module.dart';
import 'package:belluga_now/presentation/tenant/mercado/screens/mercado_screen/mercado_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'MercadoRoute')
class MercadoRoutePage extends StatelessWidget {
  const MercadoRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleScope<MercadoModule>(
      child: MercadoScreen(),
    );
  }
}
