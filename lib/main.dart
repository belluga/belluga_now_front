import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:belluga_now/application/application.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    ui.DartPluginRegistrant.ensureInitialized();
  }

  GetIt.I.registerSingleton<ApplicationContract>(Application());

  await SentryFlutter.init(
    (options) {
      options.dsn = BellugaConstants.sentry.url;
      options.tracesSampleRate = BellugaConstants.sentry.tracesSampleRate;
    },
    appRunner: _bootstrapAndRun,
  );
}

Future<void> _bootstrapAndRun() async {
  final application = GetIt.I.get<ApplicationContract>();
  try {
    await application.init();
    runApp(application);
  } catch (error, stackTrace) {
    await Sentry.captureException(error, stackTrace: stackTrace);
    runApp(
        _StartupBootstrapErrorApp(initialError: _resolveStartupError(error)));
  }
}

String _resolveStartupError(Object error) {
  return 'Não foi possível conectar ao backend para iniciar o app. '
      'Verifique sua conexão e tente novamente.\n\n$error';
}

class _StartupBootstrapErrorApp extends StatefulWidget {
  const _StartupBootstrapErrorApp({
    required this.initialError,
  });

  final String initialError;

  @override
  State<_StartupBootstrapErrorApp> createState() =>
      _StartupBootstrapErrorAppState();
}

class _StartupBootstrapErrorAppState extends State<_StartupBootstrapErrorApp> {
  bool _isRetrying = false;
  bool _showConnectivityHint = false;
  late String _errorMessage;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialError;
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _retryBootstrap() async {
    setState(() {
      _isRetrying = true;
      _showConnectivityHint = false;
      _errorMessage = 'Conectando...';
    });

    _connectivityTimer?.cancel();
    _connectivityTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted || !_isRetrying) {
        return;
      }
      setState(() {
        _showConnectivityHint = true;
      });
    });

    try {
      await GetIt.I.get<ApplicationContract>().init();
      if (!mounted) {
        return;
      }
      runApp(GetIt.I.get<ApplicationContract>());
    } catch (error, stackTrace) {
      await Sentry.captureException(error, stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _resolveStartupError(error);
      });
    } finally {
      _connectivityTimer?.cancel();
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                ),
                if (_showConnectivityHint) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Parece que você está sem conexão à internet.',
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isRetrying ? null : _retryBootstrap,
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
          ),
        ),
      ),
    );
  }
}
