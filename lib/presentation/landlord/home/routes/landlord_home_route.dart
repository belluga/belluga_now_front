import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/landlord_module.dart';
import 'package:belluga_now/presentation/landlord/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/landlord/home/screens/landlord_home_screen/landlord_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'LandlordHomeRoute')
class LandlordHomeRoutePage extends StatelessWidget {
  const LandlordHomeRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleScope<LandlordModule>(
      child: Builder(
        builder: (context) {
          return LandlordHomeScreen(
            controller: GetIt.I.get<LandlordHomeScreenController>(),
          );
        },
      ),
    );
  }
}
