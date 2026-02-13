import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/user_profile.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  Future<void> _waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
    Duration step = const Duration(milliseconds: 200),
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

  Future<void> _pumpFor(
    WidgetTester tester,
    Duration duration,
  ) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> _assertNoFrameworkExceptionFor(
    WidgetTester tester,
    Duration duration,
  ) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      final exception = tester.takeException();
      if (exception != null) {
        throw TestFailure('Unexpected framework exception: $exception');
      }
    }
  }

  void _seedAuthenticatedUser() {
    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    authRepository.userStreamValue.addValue(
      UserBelluga.fromPrimitives(
        id: '64c4f6a8d5f9a1b2c3d4e5f6',
        profile: UserProfile.fromPrimitives(
          name: 'Integration User',
          email: 'integration.user@belluga.test',
        ),
      ),
    );
  }

  Future<void> _resetContainer() async {
    await GetIt.I.reset(dispose: true);
  }

  testWidgets('Admin login via real credentials opens admin shell', (tester) async {
    await _resetContainer();

    GetIt.I.registerSingleton<AppDataRepository>(
      AppDataRepository(
        backend: AppDataBackend(),
        localInfoSource: AppDataLocalInfoSource(),
      ),
    );

    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _InMemoryAdminModeRepository(),
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));

    app.appRouter.replaceAll([const AuthLoginRoute()]);
    await _pumpFor(tester, const Duration(seconds: 1));

    await _waitForFinder(tester, find.text('Entrar como Admin'));
    await tester.tap(find.text('Entrar como Admin'));
    await _pumpFor(tester, const Duration(seconds: 1));

    final adminSheetTitle = find.text('Entrar como Admin');
    await _waitForFinder(tester, adminSheetTitle);
    final adminSheet = find.ancestor(
      of: adminSheetTitle,
      matching: find.byType(BottomSheet),
    );
    final emailField = find.descendant(
      of: adminSheet,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'E-mail',
      ),
    );
    final passwordField = find.descendant(
      of: adminSheet,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Senha',
      ),
    );
    await _waitForFinder(tester, emailField);
    await _waitForFinder(tester, passwordField);

    await tester.enterText(emailField, 'admin@bellugasolutions.com.br');
    await tester.enterText(passwordField, '765432e1');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await _assertNoFrameworkExceptionFor(tester, const Duration(seconds: 5));

    final adminShellRouter =
        find.byKey(const ValueKey('tenant-admin-shell-router'));
    await _waitForFinder(tester, adminShellRouter);
    await _waitForFinder(tester, find.text('Admin'));
    await _assertNoFrameworkExceptionFor(tester, const Duration(seconds: 2));
  });

  testWidgets(
    'Profile mode switch opens admin shell without disposed-controller errors',
    (tester) async {
      await _resetContainer();

      GetIt.I.registerSingleton<AppDataRepository>(
        AppDataRepository(
          backend: AppDataBackend(),
          localInfoSource: AppDataLocalInfoSource(),
        ),
      );

      GetIt.I.registerSingleton<AdminModeRepositoryContract>(
        _InMemoryAdminModeRepository(),
      );

      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);
      await app.init();

      _seedAuthenticatedUser();

      await tester.pumpWidget(app);
      await _pumpFor(tester, const Duration(seconds: 2));

      app.appRouter.replaceAll([const ProfileRoute()]);
      await _pumpFor(tester, const Duration(seconds: 1));
      await _waitForFinder(tester, find.text('Modo Admin'));

      final adminModeTile = find.text('Modo Admin');
      await tester.ensureVisible(adminModeTile);
      await _pumpFor(tester, const Duration(milliseconds: 300));
      await tester.tap(adminModeTile);
      await _pumpFor(tester, const Duration(seconds: 1));

      final adminSheetTitle = find.text('Entrar como Admin');
      await _waitForFinder(tester, adminSheetTitle);
      final adminSheet = find.ancestor(
        of: adminSheetTitle,
        matching: find.byType(BottomSheet),
      );
      final emailField = find.descendant(
        of: adminSheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'E-mail',
        ),
      );
      final passwordField = find.descendant(
        of: adminSheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'Senha',
        ),
      );
      await _waitForFinder(tester, emailField);
      await _waitForFinder(tester, passwordField);

      await tester.enterText(emailField, 'admin@bellugasolutions.com.br');
      await tester.enterText(passwordField, '765432e1');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await _assertNoFrameworkExceptionFor(tester, const Duration(seconds: 5));

      final adminShellRouter =
          find.byKey(const ValueKey('tenant-admin-shell-router'));
      await _waitForFinder(tester, adminShellRouter);
      await _waitForFinder(tester, find.text('Admin'));
      await _assertNoFrameworkExceptionFor(tester, const Duration(seconds: 2));
    },
  );
}

class _InMemoryAdminModeRepository implements AdminModeRepositoryContract {
  final StreamValue<AdminMode> _modeStreamValue =
      StreamValue<AdminMode>(defaultValue: AdminMode.user);

  @override
  StreamValue<AdminMode> get modeStreamValue => _modeStreamValue;

  @override
  AdminMode get mode => _modeStreamValue.value;

  @override
  bool get isLandlordMode => mode == AdminMode.landlord;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLandlordMode() async {
    _modeStreamValue.addValue(AdminMode.landlord);
  }

  @override
  Future<void> setUserMode() async {
    _modeStreamValue.addValue(AdminMode.user);
  }
}
