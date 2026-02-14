import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'support/fake_landlord_app_data_backend.dart';
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
    Duration timeout = const Duration(seconds: 20),
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

  Future<void> _waitForAny(
    WidgetTester tester,
    List<Finder> finders, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      for (final finder in finders) {
        if (finder.evaluate().isNotEmpty) {
          return;
        }
      }
    }
    throw TestFailure('Timed out waiting for any expected widget.');
  }

  testWidgets('Admin accounts ownership filters', (tester) async {
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

    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      AppDataRepository(
        backend: const FakeLandlordAppDataBackend(),
        localInfoSource: AppDataLocalInfoSource(),
      ),
    );
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _FakeAdminModeRepository(AdminMode.landlord),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    app.appRouter.replaceAll([
      const TenantAdminShellRoute(
        children: [TenantAdminAccountsListRoute()],
      ),
    ]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));

    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('tenant-admin-shell-router')),
    );
    await _waitForFinder(tester, find.text('Do tenant'));
    await _waitForAny(
      tester,
      [
        find.byType(ListTile),
        find.text('Nenhuma conta neste segmento ainda.'),
      ],
    );

    await tester.tap(find.text('Nao gerenciadas'));
    await _pumpFor(tester, const Duration(seconds: 1));
    await _waitForAny(
      tester,
      [
        find.byType(ListTile),
        find.text('Nenhuma conta neste segmento ainda.'),
      ],
    );

    await tester.tap(find.text('Do usuario'));
    await _pumpFor(tester, const Duration(seconds: 1));
    await _waitForAny(
      tester,
      [
        find.byType(ListTile),
        find.text('Nenhuma conta neste segmento ainda.'),
      ],
    );
  });
}

class _FakeAdminModeRepository implements AdminModeRepositoryContract {
  _FakeAdminModeRepository(this._mode);

  final AdminMode _mode;

  @override
  StreamValue<AdminMode> get modeStreamValue =>
      StreamValue<AdminMode>(defaultValue: _mode);

  @override
  AdminMode get mode => _mode;

  @override
  bool get isLandlordMode => _mode == AdminMode.landlord;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLandlordMode() async {}

  @override
  Future<void> setUserMode() async {}
}

class _FakeLandlordAuthRepository implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepository({required this.hasValidSession});

  @override
  final bool hasValidSession;

  @override
  String get token => hasValidSession ? 'token' : '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {}
}
