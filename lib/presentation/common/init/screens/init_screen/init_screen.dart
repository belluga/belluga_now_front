import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final appData = GetIt.I.get<AppDataRepository>().appData;
    final iconUrl = (scheme.brightness == Brightness.dark
            ? appData.mainIconDarkUrl
            : appData.mainIconLightUrl)
        .value
        ?.toString();
    return Scaffold(
      key: WidgetKeys.splash.scaffold,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: scheme.primary,
        child: Center(
          child: iconUrl != null && iconUrl.isNotEmpty
              ? Image.network(
                  iconUrl,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.waves,
                    size: 72,
                    color: scheme.onPrimary,
                  ),
                )
              : Image.asset(
                  'assets/images/logo_profile.png',
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.waves,
                    size: 72,
                    color: scheme.onPrimary,
                  ),
                ),
        ),
      ),
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

    // Always make Home the base of the stack, and stack InviteFlow on top when needed.
    final routes = <PageRouteInfo>[
      const TenantHomeRoute(),
      if (initialRoute is InviteFlowRoute) const InviteFlowRoute(),
    ];
    context.router.replaceAll(routes);
  }
}
