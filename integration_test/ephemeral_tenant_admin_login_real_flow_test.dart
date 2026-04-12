import 'dart:async';
import 'dart:ui' as ui;

import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/infrastructure/repositories/admin_mode_repository.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const adminEmailDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_EMAIL',
    defaultValue: 'admin@bellugasolutions.com.br',
  );
  const adminPasswordDefine = String.fromEnvironment(
    'LANDLORD_ADMIN_PASSWORD',
    defaultValue: '765432e1',
  );

  Future<void> clearAdminLoginStorage() async {
    await LandlordAuthRepository.storage.delete(key: 'landlord_token');
    await LandlordAuthRepository.storage.delete(key: 'landlord_user_id');
    await AdminModeRepository.storage.delete(key: 'active_mode');
  }

  Future<void> resetContainer() async {
    await GetIt.I.reset(dispose: true);
  }

  Future<void> unmountApplication(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Future<void> pumpFor(
    WidgetTester tester,
    Duration duration,
  ) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 45),
    Duration step = const Duration(milliseconds: 250),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    throw TestFailure(
      'Timed out waiting for ${finder.describeMatch(Plurality.one)}.',
    );
  }

  Future<bool> waitForMaybeFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 12),
    Duration step = const Duration(milliseconds: 250),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(step);
      if (finder.evaluate().isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  List<Object> drainFrameworkExceptions(WidgetTester tester) {
    final exceptions = <Object>[];
    while (true) {
      final exception = tester.takeException();
      if (exception == null) {
        break;
      }
      exceptions.add(exception);
    }
    return exceptions;
  }

  String textWidgetValue(Text widget) {
    final direct = widget.data?.trim();
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final rich = widget.textSpan?.toPlainText().trim();
    if (rich != null && rich.isNotEmpty) {
      return rich;
    }
    return '';
  }

  List<String> collectRenderedTexts(WidgetTester tester) {
    final values = <String>[];
    final seen = <String>{};
    for (final element in find.byType(Text, skipOffstage: false).evaluate()) {
      final widget = element.widget;
      if (widget is! Text) {
        continue;
      }
      final value = textWidgetValue(widget);
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      values.add(value);
      if (values.length >= 40) {
        break;
      }
    }
    return values;
  }

  String routerDiagnostics(ApplicationContract app) {
    final stack =
        app.appRouter.stackData.map((route) => route.name).join(' > ');
    return 'currentPath=${app.appRouter.currentPath}; '
        'topRoute=${app.appRouter.topRoute.name}; '
        'stack=$stack';
  }

  testWidgets(
    'tenant admin login on tenant domain reaches dashboard or raises exact post-submit error',
    (tester) async {
      await clearAdminLoginStorage();
      await resetContainer();

      final flutterErrors = <FlutterErrorDetails>[];
      final platformErrors = <Object>[];
      final originalFlutterError = FlutterError.onError;
      final originalPlatformError = ui.PlatformDispatcher.instance.onError;
      FlutterError.onError = (details) {
        flutterErrors.add(details);
        originalFlutterError?.call(details);
      };
      ui.PlatformDispatcher.instance.onError = (error, stack) {
        platformErrors.add(error);
        return false;
      };

      addTearDown(() async {
        FlutterError.onError = originalFlutterError;
        ui.PlatformDispatcher.instance.onError = originalPlatformError;
        await unmountApplication(tester);
        await resetContainer();
      });

      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);
      await app.init();

      await tester.pumpWidget(app);
      await pumpFor(tester, const Duration(seconds: 3));

      app.appRouter.replaceAll([const TenantAdminShellRoute()]);
      await pumpFor(tester, const Duration(seconds: 2));

      await waitForFinder(tester, find.text('Entrar como Admin'));
      await tester.tap(find.text('Entrar como Admin').last);
      await pumpFor(tester, const Duration(seconds: 1));

      final adminSheet = find.byType(BottomSheet);
      await waitForFinder(tester, adminSheet);

      final emailField = find.byKey(
        const ValueKey('landlord_login_sheet_email_field'),
      );
      final passwordField = find.byKey(
        const ValueKey('landlord_login_sheet_password_field'),
      );
      final submitButton = find.byKey(
        const ValueKey('landlord_login_sheet_submit_button'),
      );

      await waitForFinder(tester, emailField);
      await waitForFinder(tester, passwordField);
      await waitForFinder(tester, submitButton);

      await tester.enterText(emailField, adminEmailDefine);
      await tester.enterText(passwordField, adminPasswordDefine);
      tester.binding.focusManager.primaryFocus?.unfocus();
      await pumpFor(tester, const Duration(milliseconds: 500));

      await tester.tap(submitButton);
      await pumpFor(tester, const Duration(seconds: 1));

      final sawDashboard = await waitForMaybeFinder(
        tester,
        find.text('Visão geral'),
        timeout: const Duration(seconds: 18),
      );

      final frameworkExceptions = drainFrameworkExceptions(tester);
      final renderedTexts = collectRenderedTexts(tester);
      final snackbarText = renderedTexts.where(
        (value) => value.startsWith('Falha ao entrar:'),
      );

      if (flutterErrors.isNotEmpty ||
          platformErrors.isNotEmpty ||
          frameworkExceptions.isNotEmpty ||
          snackbarText.isNotEmpty ||
          !sawDashboard) {
        final flutterErrorMessages = flutterErrors
            .map((details) => details.exceptionAsString())
            .toList(growable: false);
        throw TestFailure(
          'Tenant admin login reproduction failed.\n'
          'Router: ${routerDiagnostics(app)}\n'
          'Flutter errors: ${flutterErrorMessages.isEmpty ? '<none>' : flutterErrorMessages.join(' | ')}\n'
          'Platform errors: ${platformErrors.isEmpty ? '<none>' : platformErrors.join(' | ')}\n'
          'Framework exceptions: ${frameworkExceptions.isEmpty ? '<none>' : frameworkExceptions.join(' | ')}\n'
          'Visible texts: ${renderedTexts.isEmpty ? '<none>' : renderedTexts.join(' || ')}',
        );
      }

      expect(find.text('Visão geral'), findsWidgets);
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
