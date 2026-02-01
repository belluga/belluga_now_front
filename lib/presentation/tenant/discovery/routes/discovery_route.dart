import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/discovery_module.dart';
import 'package:belluga_now/presentation/tenant/discovery/controllers/discovery_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/discovery/discovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage()
class DiscoveryRoute extends StatelessWidget {
  const DiscoveryRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<DiscoveryModule>(
      child: DiscoveryScreen(
        controller: GetIt.I.get<DiscoveryScreenController>(),
      ),
    );
  }
}
