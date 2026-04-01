import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/production_backend/production_backend.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';
import 'support/tenant_scope_guard.dart';

const kAnonymousAuthOnlyContract = true;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  const userTokenKey = 'user_token';
  const userIdKey = 'user_id';
  const deviceIdKey = 'device_id';
  const expectNonEmpty = bool.fromEnvironment(
    'AGENDA_E2E_EXPECT_NON_EMPTY',
    defaultValue: true,
  );
  const pageSize =
      int.fromEnvironment('AGENDA_E2E_PAGE_SIZE', defaultValue: 25);
  const maxDistanceOverrideRaw = String.fromEnvironment(
    'AGENDA_E2E_MAX_DISTANCE_METERS',
    defaultValue: '',
  );
  const expectedTenantMainDomain = String.fromEnvironment(
    'E2E_EXPECTED_TENANT_MAIN_DOMAIN',
    defaultValue: '',
  );

  Future<void> clearAuthStorage() async {
    await AuthRepository.storage.delete(key: userTokenKey);
    await AuthRepository.storage.delete(key: userIdKey);
    await AuthRepository.storage.delete(key: deviceIdKey);
  }

  Future<void> resetGetIt() async {
    final getIt = GetIt.I;
    if (getIt.isRegistered<AuthRepositoryContract>()) {
      getIt.unregister<AuthRepositoryContract>();
    }
    if (getIt.isRegistered<AppDataRepositoryContract>()) {
      getIt.unregister<AppDataRepositoryContract>();
    }
    if (getIt.isRegistered<BackendContract>()) {
      getIt.unregister<BackendContract>();
    }
  }

  testWidgets(
    'Home agenda eligible query returns upcoming or ongoing events against real backend',
    (_) async {
      await clearAuthStorage();
      await resetGetIt();

      final backend = ProductionBackend();
      GetIt.I.registerSingleton<BackendContract>(backend);

      final appDataRepository = AppDataRepository(
        backendContract: backend,
        localInfoSource: AppDataLocalInfoSource(),
      );
      await appDataRepository.init();
      if (expectedTenantMainDomain.trim().isNotEmpty) {
        TenantScopeGuard.assertTenantScope(
          appDataRepository.appData,
          testName: 'home-agenda-eligible-query-contract',
        );
      }
      GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
      backend.setContext(
        BackendContext.fromAppData(appDataRepository.appData),
      );

      final authRepository = AuthRepository();
      await authRepository.init();
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
      expect(
        authRepository.userToken.trim(),
        isNotEmpty,
        reason: 'Agenda e2e requires anonymous identity bootstrap to provide '
            'an authenticated token before fetching agenda.',
      );
      expect(
        authRepository.isUserLoggedIn,
        isFalse,
        reason: 'Agenda e2e must work with authenticated anonymous identity, '
            'without identified user login.',
      );

      final scheduleRepository = ScheduleRepository(
        backendContract: backend,
        appDataRepository: appDataRepository,
      );

      final origin = appDataRepository.appData.tenantDefaultOrigin;
      final maxDistanceOverride = double.tryParse(maxDistanceOverrideRaw);
      final maxDistanceMeters =
          (maxDistanceOverride != null && maxDistanceOverride > 0)
              ? maxDistanceOverride
              : appDataRepository.appData.mapRadiusMaxMeters;

      final firstPage = await scheduleRepository.getEventsPage(
        page: ScheduleRepoInt.fromRaw(1, defaultValue: 1),
        pageSize: ScheduleRepoInt.fromRaw(pageSize, defaultValue: pageSize),
        showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
        originLat: origin == null
            ? null
            : ScheduleRepoDouble.fromRaw(
                origin.latitude,
                defaultValue: origin.latitude,
              ),
        originLng: origin == null
            ? null
            : ScheduleRepoDouble.fromRaw(
                origin.longitude,
                defaultValue: origin.longitude,
              ),
        maxDistanceMeters: ScheduleRepoDouble.fromRaw(
          maxDistanceMeters,
          defaultValue: maxDistanceMeters,
        ),
      );

      expect(firstPage.events, isA<List<EventModel>>());

      if (expectNonEmpty) {
        expect(
          firstPage.events,
          isNotEmpty,
          reason: 'Expected at least one eligible event on first page. '
              'If the environment has no seed data, run with '
              '--dart-define=AGENDA_E2E_EXPECT_NON_EMPTY=false.',
        );
      }

      if (firstPage.events.isEmpty) {
        return;
      }

      final now = DateTime.now();
      final eligibleEvents = firstPage.events
          .where((event) => _isEligibleForHomeAgenda(event, now))
          .toList(growable: false);

      expect(
        eligibleEvents,
        isNotEmpty,
        reason: 'First agenda page must include at least one upcoming/ongoing '
            'event when events are returned.',
      );

      for (final event in eligibleEvents) {
        expect(event.id.value.trim(), isNotEmpty);
        expect(event.slug.trim(), isNotEmpty);
        expect(event.title.value.trim(), isNotEmpty);
        expect(event.dateTimeStart.value, isNotNull);
      }
    },
  );
}

bool _isEligibleForHomeAgenda(EventModel event, DateTime now) {
  final start = event.dateTimeStart.value;
  if (start == null) {
    return false;
  }

  final end = event.dateTimeEnd?.value ?? start.add(const Duration(hours: 3));
  final isOngoing = !now.isBefore(start) && now.isBefore(end);

  return start.isAfter(now) || isOngoing;
}
