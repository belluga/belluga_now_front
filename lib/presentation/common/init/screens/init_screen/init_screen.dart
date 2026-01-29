import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/common/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/push/push_presentation_gate.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  final _controller = GetIt.I.get<InitScreenController>();
  String? _errorMessage;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = _errorMessage;
    final appData = GetIt.I.get<AppDataRepository>().appData;
    final backgroundColor = _tryParseHexColor(appData.mainColor.value) ?? scheme.primary;
    final onBackgroundColor =
        ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final iconUrl = (scheme.brightness == Brightness.dark
            ? appData.mainIconDarkUrl
            : appData.mainIconLightUrl)
        .value
        ?.toString();
    final logo = iconUrl != null && iconUrl.isNotEmpty
        ? Image.network(
            iconUrl,
            height: 96,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.waves,
              size: 72,
              color: onBackgroundColor,
            ),
          )
        : Image.asset(
            'assets/images/logo_profile.png',
            height: 96,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.waves,
              size: 72,
              color: onBackgroundColor,
            ),
          );

    return Scaffold(
      key: WidgetKeys.splash.scaffold,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: backgroundColor,
        child: Center(
          child: error != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      logo,
                      const SizedBox(height: 24),
                      Text(
                        error,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: onBackgroundColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _isRetrying ? null : _init,
                        child: _isRetrying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : logo,
        ),
      ),
    );
  }

  Future<void> _init() async {
    // Initialize through controller
    setState(() {
      _errorMessage = null;
      _isRetrying = true;
    });
    try {
      await _controller.initialize();
    } catch (error, stackTrace) {
      debugPrint('InitScreen failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      setState(() {
        _errorMessage =
            'Não foi possível carregar o ambiente agora. Verifique sua conexão e tente novamente.';
      });
      return;
    } finally {
      setState(() {
        _isRetrying = false;
      });
    }

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
    debugPrint(
      '[Push] Init stack ready (home + invite=${initialRoute is InviteFlowRoute}).',
    );
    context.router.replaceAll(routes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (GetIt.I.isRegistered<PushPresentationGate>()) {
        debugPrint('[Push] Init stack presented; releasing push gate.');
        GetIt.I.get<PushPresentationGate>().markReady();
      }
    });
  }

  Color? _tryParseHexColor(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return null;
    final hex = normalized.startsWith('#') ? normalized.substring(1) : normalized;
    if (hex.length != 6) return null;
    final value = int.tryParse('FF$hex', radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}
