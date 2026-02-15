import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
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

  Future<void> _tapFirstMatch(WidgetTester tester, List<Finder> finders) async {
    for (final finder in finders) {
      if (finder.evaluate().isNotEmpty) {
        await tester.tap(finder.first);
        return;
      }
    }
    throw TestFailure('No tap target found.');
  }

  Finder _tenantAdminShellRouterFinder() {
    return find.byWidgetPredicate((widget) {
      final key = widget.key;
      if (key is! ValueKey<String>) {
        return false;
      }
      return key.value.startsWith('tenant-admin-shell-router-');
    });
  }

  testWidgets('Admin accounts list/detail/create routes', (tester) async {
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
    if (GetIt.I.isRegistered<LandlordTenantsRepositoryContract>()) {
      GetIt.I.unregister<LandlordTenantsRepositoryContract>();
    }

    GetIt.I.registerSingleton<AppDataRepositoryContract>(
      AppDataRepository(
        backend: const FakeLandlordAppDataBackend(),
        localInfoSource: AppDataLocalInfoSource(),
      ),
    );
    GetIt.I.registerSingleton<AdminModeRepositoryContract>(
      _InMemoryAdminModeRepository(),
    );
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _FakeLandlordAuthRepository(hasValidSession: true),
    );
    GetIt.I.registerSingleton<LandlordTenantsRepositoryContract>(
      _FakeLandlordTenantsRepository(),
    );

    final app = Application();
    GetIt.I.registerSingleton<ApplicationContract>(app);
    await app.init();

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));

    await tester.runAsync(() async {
      final adminModeRepo = GetIt.I<AdminModeRepositoryContract>();
      await adminModeRepo.setLandlordMode();
    });

    app.appRouter.replaceAll([
      const TenantAdminShellRoute(
        children: [TenantAdminAccountsListRoute()],
      ),
    ]);
    await _pumpFor(tester, const Duration(seconds: 2));

    await _waitForFinder(
      tester,
      _tenantAdminShellRouterFinder(),
    );
    app.appRouter.navigate(
      const TenantAdminShellRoute(
        children: [TenantAdminAccountsListRoute()],
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 2));
    await _waitForFinder(tester, find.text('Segmento'));
    await _waitForFinder(tester, find.text('Do tenant'));
    await _waitForAny(
      tester,
      [
        find.byType(ListTile),
        find.text('Nenhuma conta neste segmento ainda.'),
      ],
    );

    await _tapFirstMatch(
      tester,
      [
        find.widgetWithText(FloatingActionButton, 'Criar conta'),
        find.text('Criar Conta'),
      ],
    );
    await _pumpFor(tester, const Duration(seconds: 1));
    await _waitForFinder(tester, find.text('Criar Conta'));

    await tester.tap(find.byIcon(Icons.close));
    await _pumpFor(tester, const Duration(seconds: 1));
    await _waitForFinder(
      tester,
      _tenantAdminShellRouterFinder(),
    );
    app.appRouter.push(
      TenantAdminAccountDetailRoute(accountSlug: 'detalhes-tecnicos'),
    );
    await _pumpFor(tester, const Duration(seconds: 1));
    await _waitForFinder(tester, find.textContaining('Conta:'));
    await tester.tap(find.byIcon(Icons.arrow_back));
    await _pumpFor(tester, const Duration(seconds: 1));
    await _waitForFinder(
      tester,
      _tenantAdminShellRouterFinder(),
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

class _FakeLandlordAuthRepository implements LandlordAuthRepositoryContract {
  _FakeLandlordAuthRepository({required bool hasValidSession})
      : _hasValidSession = hasValidSession;

  bool _hasValidSession;

  @override
  bool get hasValidSession => _hasValidSession;

  @override
  String get token => _hasValidSession ? 'token' : '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {
    _hasValidSession = true;
  }

  @override
  Future<void> logout() async {
    _hasValidSession = false;
  }
}

class _FakeLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  @override
  Future<List<LandlordTenantOption>> fetchTenants() async {
    return const [
      LandlordTenantOption(
        id: 'tenant-guarappari',
        name: 'Guarappari',
        mainDomain: 'guarappari.local.test',
      ),
    ];
  }
}
