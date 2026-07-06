import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/observability/sentry_error_reporter.dart';
import 'package:belluga_now/application/startup/startup_bootstrap_error_presentation.dart';
import 'package:get_it/get_it.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'dart:ui' as ui;

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:belluga_now/application/application.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  if (!kIsWeb) {
    ui.DartPluginRegistrant.ensureInitialized();
  }

  GetIt.I.registerSingleton<ApplicationContract>(Application());

  await SentryFlutter.init((options) {
    options.dsn = BellugaConstants.sentry.url;
    options.tracesSampleRate = BellugaConstants.sentry.tracesSampleRate;
  }, appRunner: _bootstrapAndRun);
}

Future<void> _bootstrapAndRun() async {
  final application = GetIt.I.get<ApplicationContract>();
  try {
    await application.init();
    runApp(application);
  } catch (error, stackTrace) {
    final presentation = StartupBootstrapErrorPresentation.fromError(error);
    await _reportStartupBootstrapFailure(presentation, error, stackTrace);
    runApp(_StartupBootstrapErrorApp(initialPresentation: presentation));
  }
}

Future<void> _reportStartupBootstrapFailure(
  StartupBootstrapErrorPresentation presentation,
  Object error,
  StackTrace stackTrace,
) async {
  if (!presentation.shouldReportToSentry) {
    return;
  }

  try {
    await SentryErrorReporter.captureFatal(
      origin: 'app.bootstrap',
      error: error,
      stackTrace: stackTrace,
    );
  } catch (reportingError, reportingStackTrace) {
    debugPrint(
      'Startup bootstrap Sentry capture failed: '
      '$reportingError\n$reportingStackTrace',
    );
  }
}

class _StartupBootstrapErrorApp extends StatefulWidget {
  const _StartupBootstrapErrorApp({required this.initialPresentation});

  final StartupBootstrapErrorPresentation initialPresentation;

  @override
  State<_StartupBootstrapErrorApp> createState() =>
      _StartupBootstrapErrorAppState();
}

class _StartupBootstrapErrorAppState extends State<_StartupBootstrapErrorApp> {
  bool _isRetrying = false;
  late StartupBootstrapErrorPresentation _presentation;

  @override
  void initState() {
    super.initState();
    _presentation = widget.initialPresentation;
  }

  Future<void> _retryBootstrap() async {
    setState(() {
      _isRetrying = true;
      _presentation = StartupBootstrapErrorPresentation.retrying;
    });

    try {
      await GetIt.I.get<ApplicationContract>().init();
      if (!mounted) {
        return;
      }
      runApp(GetIt.I.get<ApplicationContract>());
    } catch (error, stackTrace) {
      final presentation = StartupBootstrapErrorPresentation.fromError(error);
      await _reportStartupBootstrapFailure(presentation, error, stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _presentation = presentation;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _presentation;
    final accentColor = _accentColorFor(presentation);
    final surfaceColor = _surfaceColorFor(presentation);

    return MaterialApp(
      locale: ApplicationContract.appLocale,
      supportedLocales: const <Locale>[ApplicationContract.appLocale],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...PhoneFieldLocalization.delegates,
      ],
      home: Scaffold(
        backgroundColor: const Color(0xFFFBF7F0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: accentColor.withValues(alpha: .20)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF1F2933).withValues(alpha: .10),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: .12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _iconFor(presentation),
                          color: accentColor,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        presentation.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: presentation.isProminent ? 24 : 22,
                          fontWeight: FontWeight.w800,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        presentation.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 16,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _isRetrying ? null : _retryBootstrap,
                          child: _isRetrying
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Tentar novamente'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentColorFor(StartupBootstrapErrorPresentation presentation) {
    return switch (presentation.kind) {
      StartupBootstrapErrorKind.connectivity => const Color(0xFFB42318),
      StartupBootstrapErrorKind.retrying => const Color(0xFF0F766E),
      StartupBootstrapErrorKind.internal => const Color(0xFF1D4ED8),
    };
  }

  Color _surfaceColorFor(StartupBootstrapErrorPresentation presentation) {
    return switch (presentation.kind) {
      StartupBootstrapErrorKind.connectivity => const Color(0xFFFFF1F0),
      StartupBootstrapErrorKind.retrying => const Color(0xFFEFFCF8),
      StartupBootstrapErrorKind.internal => const Color(0xFFEFF6FF),
    };
  }

  IconData _iconFor(StartupBootstrapErrorPresentation presentation) {
    return switch (presentation.kind) {
      StartupBootstrapErrorKind.connectivity => Icons.wifi_off_rounded,
      StartupBootstrapErrorKind.retrying => Icons.sync_rounded,
      StartupBootstrapErrorKind.internal => Icons.error_outline_rounded,
    };
  }
}
