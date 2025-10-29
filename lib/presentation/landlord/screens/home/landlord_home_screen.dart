import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/landlord/screens/home/controllers/landlord_home_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:get_it/get_it.dart';

@RoutePage()
class LandlordHomeScreen extends StatefulWidget {
  const LandlordHomeScreen({super.key});

  @override
  State<LandlordHomeScreen> createState() => _LandlordHomeScreenState();
}

class _LandlordHomeScreenState extends State<LandlordHomeScreen> {

  late LandlordHomeScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton<LandlordHomeScreenController>(
      LandlordHomeScreenController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This is Landlord HOME (Belluga NOW)"),
            Text(BellugaConstants.settings.platform),
            // ElevatedButton(
            //   key: WidgetKeys.auth.navigateToProtectedButton,
            //   onPressed: () => context.router.push(const DashboardRoute()),
            //   child: const Text("goto Protected"),
            // ),
          ],
        ),
      ),
    );
  }
}
