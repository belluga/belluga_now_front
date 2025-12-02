import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_prototype_module.dart';
import 'package:belluga_now/presentation/prototypes/map_experience/map_experience_prototype_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'MapExperiencePrototypeRoute')
class MapExperiencePrototypeRoutePage extends StatelessWidget {
  const MapExperiencePrototypeRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModuleScope<MapPrototypeModule>(
      child: MapExperiencePrototypeScreen(),
    );
  }
}
