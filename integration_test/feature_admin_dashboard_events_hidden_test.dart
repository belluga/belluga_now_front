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

  testWidgets('Admin dashboard hides events', (tester) async {
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

    await tester.runAsync(() async {
      final adminModeRepo = GetIt.I<AdminModeRepositoryContract>();
      await adminModeRepo.setLandlordMode();
      final authRepo = GetIt.I<LandlordAuthRepositoryContract>();
      await authRepo.loginWithEmailPassword(
        'admin@bellugasolutions.com.br',
        '765432e1',
      );
    });

    app.appRouter.replaceAll([const TenantAdminShellRoute()]);

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));

    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('tenant-admin-shell-router')),
    );
    await _waitForFinder(tester, find.text('Eventos'));
    await _waitForFinder(tester, find.text('Em breve'));

    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Eventos'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await _waitForFinder(
      tester,
      find.byKey(const ValueKey('tenant-admin-shell-router')),
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
