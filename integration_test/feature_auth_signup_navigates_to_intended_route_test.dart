import 'dart:async';
import 'dart:developer' as developer;

import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/controllers/auth_login_controller.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/auth_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  developer.postEvent(
    'integration_test.VmServiceProxyGoldenFileComparator',
    const {},
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();
  final originalGeolocator = GeolocatorPlatform.instance;

  setUpAll(() {
    GeolocatorPlatform.instance = _TestGeolocatorPlatform();
  });

  tearDownAll(() {
    GeolocatorPlatform.instance = originalGeolocator;
  });

  const userTokenKey = 'user_token';
  const userIdKey = 'user_id';
  const deviceIdKey = 'device_id';

  Future<void> _clearAuthStorage() async {
    await AuthRepository.storage.delete(key: userTokenKey);
    await AuthRepository.storage.delete(key: userIdKey);
    await AuthRepository.storage.delete(key: deviceIdKey);
  }

  Future<void> _waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 45),
    Duration step = const Duration(milliseconds: 300),
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

  Future<void> _waitForRoute(
    ApplicationContract app,
    String routeName, {
    Duration timeout = const Duration(seconds: 45),
    Duration step = const Duration(milliseconds: 300),
  }) async {
    final deadline = DateTime.now().add(timeout);
    String? lastRouteName;
    String? lastPath;
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(step);
      lastRouteName = app.appRouter.topRoute.name;
      lastPath = app.appRouter.currentPath;
      if (lastRouteName == routeName) {
        return;
      }
    }
    throw TestFailure(
      'Timed out waiting for route $routeName. '
      'Last route=$lastRouteName path=$lastPath.',
    );
  }

  Future<bool> _waitForMaybeFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 8),
    Duration step = const Duration(milliseconds: 300),
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

  Future<void> _pumpFor(
    WidgetTester tester,
    Duration duration,
  ) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> _dismissInviteOverlayIfNeeded(WidgetTester tester) async {
    final closeButton = find.byTooltip('Fechar');
    if (await _waitForMaybeFinder(tester, closeButton)) {
      await tester.tap(closeButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
    }
  }

  Future<void> _dismissLocationGateIfNeeded(WidgetTester tester) async {
    final allowButton = find.text('Permitir localização');
    if (await _waitForMaybeFinder(tester, allowButton)) {
      await tester.tap(allowButton.first);
      await _pumpFor(tester, const Duration(seconds: 2));
    }

    final continueButton = find.text('Continuar sem localização ao vivo');
    if (await _waitForMaybeFinder(tester, continueButton)) {
      await tester.tap(continueButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
    }

    final notNowButton = find.text('Agora não');
    if (await _waitForMaybeFinder(tester, notNowButton)) {
      await tester.tap(notNowButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));
    }
  }

  testWidgets(
    'Signup navigates back to intended route',
    (tester) async {
      await _clearAuthStorage();
      if (GetIt.I.isRegistered<ApplicationContract>()) {
        GetIt.I.unregister<ApplicationContract>();
      }
      if (GetIt.I.isRegistered<AppDataRepository>()) {
        GetIt.I.unregister<AppDataRepository>();
      }
      GetIt.I.registerSingleton<AppDataRepository>(
        AppDataRepository(
          backend: AppDataBackend(),
          localInfoSource: AppDataLocalInfoSource(),
        ),
      );

      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);
      await app.init();

      if (GetIt.I.isRegistered<AuthLoginControllerContract>()) {
        GetIt.I.unregister<AuthLoginControllerContract>();
      }
      final loginController = AuthLoginController();
      GetIt.I.registerSingleton<AuthLoginControllerContract>(
        loginController,
      );

      await tester.pumpWidget(app);
      await _pumpFor(tester, const Duration(seconds: 2));

      app.appRouter.replaceAll([EventSearchRoute()]);
      await _pumpFor(tester, const Duration(seconds: 1));
      app.appRouter.pushPath('/auth/login?redirect=%2Fagenda');
      await _pumpFor(tester, const Duration(seconds: 1));
      await _waitForFinder(
        tester,
        find.byType(AuthLoginScreen, skipOffstage: false),
      );

      final openSignupButton = find.widgetWithText(TextButton, 'Criar conta');
      await _waitForFinder(tester, openSignupButton.first);
      await tester.tap(openSignupButton.first);
      await _pumpFor(tester, const Duration(seconds: 1));

      final bottomSheet = find.byType(BottomSheet);
      await _waitForFinder(tester, bottomSheet);
      await _waitForFinder(
        tester,
        find.descendant(
          of: bottomSheet,
          matching: find.text('Criar conta'),
        ),
      );

      final nameField = find.descendant(
        of: bottomSheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'Nome',
        ),
      );
      final emailField = find.descendant(
        of: bottomSheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'E-mail',
        ),
      );
      final passwordField = find.descendant(
        of: bottomSheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'Senha',
        ),
      );
      await _waitForFinder(tester, nameField);
      await _waitForFinder(tester, emailField);
      await _waitForFinder(tester, passwordField);

      final now = DateTime.now().millisecondsSinceEpoch;
      await tester.enterText(nameField, 'Signup Regression');
      await tester.enterText(
        emailField,
        'signup-ui-$now@belluga.test',
      );
      await tester.enterText(passwordField, 'SecurePass!123');
      await tester.pump();

      String? signupError;
      final signupResult = Completer<bool>();
      final resultSub = loginController.signUpResultStreamValue.stream.listen(
        (value) {
          if (value == null) return;
          if (!signupResult.isCompleted) {
            signupResult.complete(value);
          }
        },
      );
      final errorSub = loginController.generalErrorStreamValue.stream.listen(
        (value) {
          if (value != null && value.trim().isNotEmpty) {
            signupError = value.trim();
          }
        },
      );
      addTearDown(() async {
        await resultSub.cancel();
        await errorSub.cancel();
      });

      final submitButton = find.widgetWithText(FilledButton, 'Criar conta');
      await _waitForFinder(tester, submitButton);
      await tester.tap(submitButton);
      await _pumpFor(tester, const Duration(seconds: 2));

      await _dismissLocationGateIfNeeded(tester);
      await _dismissInviteOverlayIfNeeded(tester);

      final didSignUp = await signupResult.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TestFailure(
            'Timed out waiting for signup result.'
            '${signupError != null ? ' Last error: $signupError' : ''}',
          );
        },
      );
      if (!didSignUp) {
        throw TestFailure(
          'Signup failed: ${signupError ?? 'Erro desconhecido'}',
        );
      }

      await _waitForRoute(app, EventSearchRoute.name);
    },
  );
}

class _TestGeolocatorPlatform extends GeolocatorPlatform {
  static final Position _position = Position(
    latitude: -20.6772,
    longitude: -40.5093,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    accuracy: 5.0,
    altitude: 1.0,
    altitudeAccuracy: 1.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 0.0,
    speedAccuracy: 1.0,
  );

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async =>
      _position;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async =>
      _position;
}
