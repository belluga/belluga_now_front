import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/domain/controllers/belluga_init_screen_controller_contract.dart';
import 'package:belluga_now/presentation/common/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:get_it/get_it.dart';

@RoutePage()
class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  late final BellugaInitScreenControllerContract _controller;

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
    _controller =
        GetIt.I.registerSingleton<BellugaInitScreenControllerContract>(
      InitScreenController(),
    );
    await _controller.initialize();

    await Future.delayed(const Duration(milliseconds: 2000));
    _gotoInitialRoute();
  }

  void _gotoInitialRoute() => context.router.replace(_controller.initialRoute);

  @override
  void dispose() {
    super.dispose();
    GetIt.I.unregister<BellugaInitScreenControllerContract>();
  }
}
