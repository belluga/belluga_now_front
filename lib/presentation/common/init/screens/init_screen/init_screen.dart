import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:get_it/get_it.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  final _controller = GetIt.I.get<InitScreenController>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: WidgetKeys.splash.scaffold,
      body: const Center(child: Text("SPLASH")),
    );
  }

  Future<void> _init() async {
    // Initialize through controller
    await _controller.initialize();

    // Small delay for splash screen
    await Future.delayed(const Duration(milliseconds: 1000));

    // Navigate to initial route determined by controller
    _gotoInitialRoute();
  }

  void _gotoInitialRoute() {
    final initialRoute = _controller.initialRoute;

    // Always push TenantHomeRoute first to establish the base stack
    context.router.pushAndPopUntil(
      const TenantHomeRoute(),
      predicate: (route) => false,
    );

    // If the controller determined we should show invites, push it on top
    if (initialRoute is InviteFlowRoute) {
      context.router.push(const InviteFlowRoute());
    }
  }
}
