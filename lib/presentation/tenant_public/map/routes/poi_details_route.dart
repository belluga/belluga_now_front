import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/map_module.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'PoiDetailsRoute')
class PoiDetailsRoutePage extends StatelessWidget {
  const PoiDetailsRoutePage({
    super.key,
    @QueryParam('poi') this.poi,
    @QueryParam('stack') this.stack,
  });

  final String? poi;
  final String? stack;

  @override
  Widget build(BuildContext context) {
    return ModuleScope<MapModule>(
      child: MapScreen(
        initialPoiQuery: poi,
        initialPoiStackQuery: stack,
      ),
    );
  }
}
