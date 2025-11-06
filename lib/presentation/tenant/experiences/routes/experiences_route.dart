import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/experiences_module.dart';
import 'package:belluga_now/presentation/tenant/experiences/screens/experiences_screen/experiences_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'ExperiencesRoute')
class ExperiencesRoutePage extends StatelessWidget {
  const ExperiencesRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleScope<ExperiencesModule>(
      child: ExperiencesScreen(),
    );
  }
}
