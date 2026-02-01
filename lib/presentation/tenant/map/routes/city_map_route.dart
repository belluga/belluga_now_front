import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_module.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/controllers/map_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/map/screens/map_screen/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'CityMapRoute')
class CityMapRoutePage extends StatelessWidget {
  const CityMapRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<MapModule>(
      child: MapScreen(
        controller: GetIt.I.get<MapScreenController>(),
        fabMenuController: GetIt.I.get<FabMenuController>(),
      ),
    );
  }
}
