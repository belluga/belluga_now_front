import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/screens/home_tenant/controllers/tenant_home_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:get_it/get_it.dart';

@RoutePage()
class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {

  late TenantHomeScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I.registerSingleton<TenantHomeScreenController>(
      TenantHomeScreenController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This is Tenant HOME (Belluga NOW)"),
            Text(_controller.tenant.toString()),
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
