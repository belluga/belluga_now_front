import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/belluga_constants.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/widget_keys.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/tenant/tenant.dart';
import 'package:flutter_laravel_backend_boilerplate/application/router/app_router.gr.dart';
import 'package:get_it/get_it.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("This is HOME"),
            Text(GetIt.I.get<Tenant>().hostname),
            Text(BellugaConstants.settings.platform),
            ElevatedButton(
              key: WidgetKeys.auth.navigateToProtectedButton,
              onPressed: () => context.router.push(const DashboardRoute()),
              child: const Text("goto Protected"),
            ),
          ],
        ),
      ),
    );
  }
}
