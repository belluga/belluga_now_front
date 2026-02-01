import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/initialization_module.dart';
import 'package:belluga_now/presentation/common/init/screens/init_screen/init_screen.dart';
import 'package:belluga_now/presentation/common/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'InitRoute')
class InitRoutePage extends StatelessWidget {
  const InitRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<InitializationModule>(
      child: InitScreen(
        controller: GetIt.I.get<InitScreenController>(),
      ),
    );
  }
}
