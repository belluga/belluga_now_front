import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/dal/dao/local/app_data_local_info_source/app_data_local_info_source_stub.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

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

  testWidgets('Admin login via real credentials opens admin shell', (tester) async {
    if (GetIt.I.isRegistered<ApplicationContract>()) {
      GetIt.I.unregister<ApplicationContract>();
    }
    if (GetIt.I.isRegistered<AppDataRepository>()) {
      GetIt.I.unregister<AppDataRepository>();
    }
    if (GetIt.I.isRegistered<AdminModeRepositoryContract>()) {
      GetIt.I.unregister<AdminModeRepositoryContract>();
    }
    if (GetIt.I.isRegistered<LandlordAuthRepositoryContract>()) {
      GetIt.I.unregister<LandlordAuthRepositoryContract>();
    }

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
    await _pumpFor(tester, const Duration(seconds: 3));

    await _waitForFinder(tester, find.text('MODO ADMINISTRADOR'));
  });
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
