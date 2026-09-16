import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/fake_landlord_app_data_backend.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  setUp(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'compiled app has no Static route or admin destination and keeps survivors',
    (tester) async {
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
        _FakeLandlordAuthRepository(),
      );
      GetIt.I.registerSingleton<LandlordTenantsRepositoryContract>(
        _FakeLandlordTenantsRepository(),
      );

      final app = Application();
      GetIt.I.registerSingleton<ApplicationContract>(app);
      await app.init();

      final routeInventory = _flattenRoutes(app.appRouter.routes)
          .map((route) => '${route.name}:${route.path}'.toLowerCase())
          .toList(growable: false);
      expect(
        routeInventory.where(
          (entry) => entry.contains('static') || entry.contains('/ativos'),
        ),
        isEmpty,
      );
      expect(routeInventory, contains('citymaproute:/mapa'));
      expect(routeInventory, contains('poidetailsroute:/mapa/poi'));
      expect(
        routeInventory.any((entry) => entry.startsWith('partnerdetailroute:')),
        isTrue,
      );
      expect(
        routeInventory.any(
          (entry) => entry.startsWith('tenantadmineventsroute:'),
        ),
        isTrue,
      );

      await GetIt.I<AdminModeRepositoryContract>().setLandlordMode();
      app.appRouter.replaceAll([const TenantAdminShellRoute()]);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Eventos'), findsWidgets);
      expect(find.text('Contas'), findsWidgets);
      expect(find.text('Config'), findsWidgets);
      expect(find.text('Ativos'), findsNothing);
      expect(find.text('Ativos estáticos'), findsNothing);
      expect(find.text('Tipos de Ativo'), findsNothing);
    },
  );
}

Iterable<AutoRoute> _flattenRoutes(Iterable<AutoRoute> routes) sync* {
  for (final route in routes) {
    yield route;
    yield* _flattenRoutes(route.children ?? const <AutoRoute>[]);
  }
}

class _InMemoryAdminModeRepository implements AdminModeRepositoryContract {
  final StreamValue<AdminMode> _modeStreamValue = StreamValue<AdminMode>(
    defaultValue: AdminMode.user,
  );

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
  @override
  bool hasValidSession = true;

  @override
  String get token => 'token';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
    LandlordAuthRepositoryContractPrimString email,
    LandlordAuthRepositoryContractPrimString password,
  ) async {
    hasValidSession = true;
  }

  @override
  Future<void> logout() async {
    hasValidSession = false;
  }
}

class _FakeLandlordTenantsRepository
    implements LandlordTenantsRepositoryContract {
  @override
  Future<List<LandlordTenantOption>> fetchTenants() async {
    return [
      landlordTenantOptionFromRaw(
        id: 'tenant-guarappari',
        name: 'Guarappari',
        mainDomain: 'guarappari.local.test',
      ),
    ];
  }
}
