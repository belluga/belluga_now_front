import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/location_origin_reason.dart';
import 'package:belluga_now/domain/app_data/location_origin_settings.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/schedule_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_text_value.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_app_bar.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_body.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_section_view.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

List<EventModel>? _displayedEvents(TenantHomeAgendaController controller) =>
    controller.displayStateStreamValue.value?.events;

void main() {
  group('TenantHomeAgendaController radius bounds', () {
    test('initializes from tenant radius default and exposes min bound',
        () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final controller = _buildAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.minRadiusMeters, 2000);
      expect(controller.radiusMetersStreamValue.value, 7000);

      controller.onDispose();
    });

    test('initializes from persisted user radius preference when available',
        () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(
        appData,
        initialMaxRadiusMeters: 9000,
        hasPersistedMaxRadiusPreference: true,
      );
      final controller = _buildAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.radiusMetersStreamValue.value, 9000);

      controller.onDispose();
    });

    test(
      'seeds initial radius from distance to tenant origin when no preference exists',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 50,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final userCoordinate = CityCoordinate(
          latitudeValue: LatitudeValue()..parse('-20.850000'),
          longitudeValue: LongitudeValue()..parse('-40.495395'),
        );
        final expectedMeters = haversineDistanceMeters(
          coordinateA: userCoordinate,
          coordinateB: appData.tenantDefaultOrigin!,
        ).value;
        final scheduleRepository = _FakeScheduleRepository();
        final locationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(userCoordinate);
        final controller = _buildAgendaController(
          scheduleRepository: scheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
          radiusRefreshDebounce: const Duration(days: 1),
        );

        await controller.init();

        expect(
          controller.radiusMetersStreamValue.value,
          closeTo(expectedMeters, 0.001),
        );
        expect(
          appDataRepository.maxRadiusMeters.value,
          closeTo(expectedMeters, 0.001),
        );
        expect(appDataRepository.setMaxRadiusMetersCallCount, 1);

        controller.onDispose();
      },
    );

    test(
      'seeds initial radius to tenant max when user is farther than tenant max and no preference exists',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final scheduleRepository = _FakeScheduleRepository();
        final locationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(
            CityCoordinate(
              latitudeValue: LatitudeValue()..parse('-23.550520'),
              longitudeValue: LongitudeValue()..parse('-46.633308'),
            ),
          );
        final controller = _buildAgendaController(
          scheduleRepository: scheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
          radiusRefreshDebounce: const Duration(days: 1),
        );

        await controller.init();

        expect(controller.radiusMetersStreamValue.value, 10000);
        expect(appDataRepository.maxRadiusMeters.value, 10000);
        expect(appDataRepository.setMaxRadiusMetersCallCount, 1);

        controller.onDispose();
      },
    );

    test('clamps radius updates to tenant bounds and reacts to max changes',
        () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final controller = _buildAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      controller.setRadiusMeters(1000);
      expect(controller.radiusMetersStreamValue.value, 2000);

      controller.setRadiusMeters(25000);
      expect(controller.radiusMetersStreamValue.value, 15000);

      await appDataRepository.setMaxRadiusMeters(
        DistanceInMetersValue.fromRaw(5000, defaultValue: 5000),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.radiusMetersStreamValue.value, 5000);

      controller.onDispose();
    });

    test(
      'persists selected radius preference without collapsing tenant max bound',
      () async {
        final appData = _buildAppData(
          minKm: 2,
          defaultKm: 7,
          maxKm: 15,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final controller = _buildAgendaController(
          scheduleRepository: _FakeScheduleRepository(),
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: appDataRepository,
          radiusRefreshDebounce: const Duration(days: 1),
        );

        await controller.init();

        expect(controller.maxRadiusMetersStreamValue.value, 15000);

        controller.setRadiusMeters(4000);
        await Future<void>.delayed(Duration.zero);

        expect(appDataRepository.setMaxRadiusMetersCallCount, 1);
        expect(appDataRepository.maxRadiusMeters.value, 4000);
        expect(controller.radiusMetersStreamValue.value, 4000);
        expect(
          controller.maxRadiusMetersStreamValue.value,
          15000,
          reason: 'Persisted selection must not shrink the tenant max bound.',
        );

        controller.setRadiusMeters(12000);
        expect(
          controller.radiusMetersStreamValue.value,
          12000,
          reason:
              'A lower persisted preference must not block future increases up to tenant max.',
        );

        controller.onDispose();
      },
    );

    test('coalesces rapid radius updates into a single refresh', () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
        radiusRefreshDebounce: const Duration(milliseconds: 40),
      );

      await controller.init();
      expect(scheduleRepository.getEventsPageCallCount, 1);

      controller.setRadiusMeters(4000);
      controller.setRadiusMeters(5000);
      controller.setRadiusMeters(6000);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        scheduleRepository.getEventsPageCallCount,
        1,
        reason: 'Should not refresh before debounce window closes.',
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(
        scheduleRepository.getEventsPageCallCount,
        2,
        reason: 'Rapid radius updates must coalesce into one fetch.',
      );

      controller.onDispose();
    });

    test('keeps radius refresh loading active until repository refresh settles',
        () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
        radiusRefreshDebounce: const Duration(milliseconds: 20),
      );

      await controller.init();
      expect(controller.isRadiusRefreshLoadingStreamValue.value, isFalse);

      final pendingRefresh = Completer<void>();
      scheduleRepository.nextFetchGate = pendingRefresh;

      controller.setRadiusMeters(4000);
      expect(controller.isRadiusRefreshLoadingStreamValue.value, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(
        scheduleRepository.getEventsPageCallCount,
        1,
        reason: 'Refresh should still be waiting on the debounce window.',
      );
      expect(controller.isRadiusRefreshLoadingStreamValue.value, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(scheduleRepository.getEventsPageCallCount, 2);
      expect(controller.isRadiusRefreshLoadingStreamValue.value, isTrue);

      pendingRefresh.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(controller.isRadiusRefreshLoadingStreamValue.value, isFalse);

      controller.onDispose();
    });

    test('normalizes invalid tenant radius settings when parsing app data', () {
      final appData = _buildAppData(
        minKm: 10,
        defaultKm: 30,
        maxKm: 20,
      );

      expect(appData.mapRadiusMinMeters, 10000);
      expect(appData.mapRadiusMaxMeters, 20000);
      expect(appData.mapRadiusDefaultMeters, 20000);
    });

    test('finalizes initial loading even when first fetch fails', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final controller = _buildAgendaController(
        scheduleRepository: _FailingScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(_displayedEvents(controller), isNull);

      controller.onDispose();
    });

    test('retries first page once after transient fetch failure', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FailingOnceScheduleRepository();
      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 2);
      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(_displayedEvents(controller), isEmpty);

      controller.onDispose();
    });

    test('retries first page once and publishes recovered events', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );
      final backend = _FailingOnceThenDataBackend();
      final controller = _buildAgendaController(
        scheduleRepository: ScheduleRepository(backend: backend),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(backend.fetchEventsPageCallCount, 2);
      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(_displayedEvents(controller), hasLength(1));
      expect(
        _displayedEvents(controller)!.first.title.value,
        'Evento Recuperado',
      );

      controller.onDispose();
    });

    test('reuses cached agenda stream on subsequent init calls', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(_displayedEvents(controller), isNotNull);

      await controller.init();
      expect(
        scheduleRepository.getEventsPageCallCount,
        1,
        reason: 'Second init must reuse cached StreamValue state.',
      );

      controller.onDispose();
    });

    test(
      'reuses repository StreamValue cache across controller instances',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final sharedScheduleRepository = _FakeScheduleRepository();

        final firstController = _buildAgendaController(
          scheduleRepository: sharedScheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: appDataRepository,
        );
        await firstController.init();
        expect(sharedScheduleRepository.getEventsPageCallCount, 1);
        firstController.onDispose();

        final secondController = _buildAgendaController(
          scheduleRepository: sharedScheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: appDataRepository,
        );
        await secondController.init();
        expect(
          sharedScheduleRepository.getEventsPageCallCount,
          1,
          reason:
              'Second controller must hydrate from repository StreamValue cache.',
        );
        secondController.onDispose();
      },
    );

    test(
      'ignores stale empty cache when effective origin differs from snapshot origin',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final locationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(
            CityCoordinate(
              latitudeValue: LatitudeValue()..parse('-20.671339'),
              longitudeValue: LongitudeValue()..parse('-40.495395'),
            ),
          );
        final backend = _CountingPayloadScheduleBackend();
        final scheduleRepository = ScheduleRepository(backend: backend);
        await scheduleRepository.loadHomeAgenda(
          showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
          searchQuery: ScheduleRepoString.fromRaw('', defaultValue: ''),
          confirmedOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
          originLat: ScheduleRepoDouble.fromRaw(-21.0, defaultValue: -21.0),
          originLng: ScheduleRepoDouble.fromRaw(-41.0, defaultValue: -41.0),
          maxDistanceMeters:
              ScheduleRepoDouble.fromRaw(50000, defaultValue: 50000),
        );
        final baselineFetchCalls = backend.fetchEventsPageCallCount;

        final controller = _buildAgendaController(
          scheduleRepository: scheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
        );

        await controller.init();

        expect(
          backend.fetchEventsPageCallCount,
          baselineFetchCalls + 1,
          reason:
              'Stale cache with mismatched origin must not suppress the first real fetch.',
        );
        expect(_displayedEvents(controller), hasLength(1));
        expect(
          _displayedEvents(controller)!.first.title.value,
          'Evento Teste',
        );

        controller.onDispose();
      },
    );

    test('retries init when previous load ended without cached results',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _AlwaysFailingScheduleRepository();
      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(_displayedEvents(controller), isNull);
      expect(scheduleRepository.getEventsPageCallCount, 2);

      await controller.init();
      expect(
        scheduleRepository.getEventsPageCallCount,
        4,
        reason: 'When cache is null, init must retry fetching.',
      );

      controller.onDispose();
    });

    test('shows invite filter action for anonymous app sessions', () {
      final controller = _buildAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(
          _buildAppData(
            minKm: 1,
            defaultKm: 5,
            maxKm: 10,
          ),
        ),
        authRepository: _FakeAuthRepository(authorized: false),
        isWebRuntime: false,
      );

      expect(controller.shouldShowInviteFilterAction, isTrue);

      controller.onDispose();
    });

    testWidgets(
      'hides invite filter on unauthenticated web and reveals it after auth',
      (tester) async {
        final authRepository = _FakeAuthRepository(authorized: false);
        final controller = _buildAgendaController(
          scheduleRepository: _FakeScheduleRepository(),
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: _FakeAppDataRepository(
            _buildAppData(
              minKm: 1,
              defaultKm: 5,
              maxKm: 10,
            ),
          ),
          authRepository: authRepository,
          isWebRuntime: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: HomeAgendaAppBar(controller: controller),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        );

        expect(find.byTooltip('Todos os eventos'), findsNothing);

        authRepository.setAuthorized(true);
        await tester.pump();

        expect(find.byTooltip('Todos os eventos'), findsOneWidget);

        controller.onDispose();
      },
    );

    testWidgets(
      'home radius sheet shows explanatory copy and persistence note',
      (tester) async {
        final controller = _buildAgendaController(
          scheduleRepository: _FakeScheduleRepository(),
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: _FakeAppDataRepository(
            _buildAppData(
              minKm: 1,
              defaultKm: 5,
              maxKm: 15,
            ),
          ),
        );

        await controller.init();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: HomeAgendaAppBar(controller: controller),
              ),
              body: const SizedBox.shrink(),
            ),
          ),
        );

        await tester
            .tap(find.byKey(const ValueKey<String>('agenda-radius-expanded')));
        await tester.pumpAndSettle();

        expect(find.text('Distância Máxima'), findsOneWidget);
        expect(
          find.text(
            'Mostraremos apenas eventos acontecendo dentro desse raio a partir de sua localização.',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            'Você pode alterar essa preferência quando quiser.',
          ),
          findsOneWidget,
        );
        expect(find.text('Confirmar raio'), findsOneWidget);

        controller.onDispose();
      },
    );

    testWidgets('home radius action shows loading affordance while refreshing',
        (tester) async {
      final controller = _buildAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(
          _buildAppData(
            minKm: 1,
            defaultKm: 5,
            maxKm: 15,
          ),
        ),
      );

      await controller.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: HomeAgendaAppBar(controller: controller),
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byIcon(Icons.place_outlined), findsOneWidget);

      controller.isRadiusRefreshLoadingStreamValue.addValue(true);
      await tester.pump();

      expect(find.byIcon(Icons.place_outlined), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.onDispose();
    });

    test('uses tenant default origin when user location is unavailable',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false;

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(locationRepository.warmUpCalled, isTrue);
      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(scheduleRepository.lastOriginLat, closeTo(-20.671339, 0.000001));
      expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));
      expect(
        appDataRepository.locationOriginSettings?.usesFixedReference,
        isTrue,
      );
      expect(
        appDataRepository.locationOriginSettings?.reason,
        LocationOriginReason.unavailable,
      );

      controller.onDispose();
    });

    test(
      'uses live user location and persists live mode when within tenant max radius of tenant origin',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final scheduleRepository = _FakeScheduleRepository();
        final locationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(
            CityCoordinate(
              latitudeValue: LatitudeValue()..parse('-20.675000'),
              longitudeValue: LongitudeValue()..parse('-40.500000'),
            ),
          );

        final controller = _buildAgendaController(
          scheduleRepository: scheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
        );

        await controller.init();

        expect(scheduleRepository.lastOriginLat, closeTo(-20.675000, 0.000001));
        expect(scheduleRepository.lastOriginLng, closeTo(-40.500000, 0.000001));
        expect(appDataRepository.setLocationOriginSettingsCallCount, 1);
        expect(
          appDataRepository.locationOriginSettings?.usesUserLiveLocation,
          isTrue,
        );
        expect(
          appDataRepository.locationOriginSettings?.fixedLocationReference,
          isNull,
        );

        controller.onDispose();
      },
    );

    test(
      'uses tenant default origin and persists fixed reference when user is outside tenant max radius',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final scheduleRepository = _FakeScheduleRepository();
        final locationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(
            CityCoordinate(
              latitudeValue: LatitudeValue()..parse('-23.550520'),
              longitudeValue: LongitudeValue()..parse('-46.633308'),
            ),
          );

        final controller = _buildAgendaController(
          scheduleRepository: scheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
        );

        await controller.init();

        expect(scheduleRepository.lastOriginLat, closeTo(-20.671339, 0.000001));
        expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));
        expect(appDataRepository.setLocationOriginSettingsCallCount, 1);
        expect(
          appDataRepository.locationOriginSettings?.usesFixedReference,
          isTrue,
        );
        expect(
          appDataRepository.locationOriginSettings?.reason,
          LocationOriginReason.outsideRange,
        );
        expect(
          appDataRepository
              .locationOriginSettings?.fixedLocationReference?.latitude,
          closeTo(-20.671339, 0.000001),
        );
        expect(
          appDataRepository
              .locationOriginSettings?.fixedLocationReference?.longitude,
          closeTo(-40.495395, 0.000001),
        );

        controller.onDispose();
      },
    );

    test(
      'uses tenant max radius as the boundary instead of a fixed 50km rule',
      () async {
        final userCoordinate = CityCoordinate(
          latitudeValue: LatitudeValue()..parse('-20.850000'),
          longitudeValue: LongitudeValue()..parse('-40.495395'),
        );

        final withinTenantMaxRepository = _FakeAppDataRepository(
          _buildAppData(
            minKm: 1,
            defaultKm: 5,
            maxKm: 30,
          ),
        );
        final withinTenantMaxScheduleRepository = _FakeScheduleRepository();
        final withinTenantMaxLocationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(userCoordinate);

        final withinTenantMaxController = _buildAgendaController(
          scheduleRepository: withinTenantMaxScheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: withinTenantMaxLocationRepository,
          appDataRepository: withinTenantMaxRepository,
        );

        await withinTenantMaxController.init();

        expect(
          withinTenantMaxScheduleRepository.lastOriginLat,
          closeTo(-20.850000, 0.000001),
        );
        expect(
          withinTenantMaxScheduleRepository.lastOriginLng,
          closeTo(-40.495395, 0.000001),
        );
        expect(
          withinTenantMaxRepository
              .locationOriginSettings?.usesUserLiveLocation,
          isTrue,
        );

        withinTenantMaxController.onDispose();

        final outsideTenantMaxRepository = _FakeAppDataRepository(
          _buildAppData(
            minKm: 1,
            defaultKm: 5,
            maxKm: 10,
          ),
        );
        final outsideTenantMaxScheduleRepository = _FakeScheduleRepository();
        final outsideTenantMaxLocationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(userCoordinate);

        final outsideTenantMaxController = _buildAgendaController(
          scheduleRepository: outsideTenantMaxScheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: outsideTenantMaxLocationRepository,
          appDataRepository: outsideTenantMaxRepository,
        );

        await outsideTenantMaxController.init();

        expect(
          outsideTenantMaxScheduleRepository.lastOriginLat,
          closeTo(-20.671339, 0.000001),
        );
        expect(
          outsideTenantMaxScheduleRepository.lastOriginLng,
          closeTo(-40.495395, 0.000001),
        );
        expect(
          outsideTenantMaxRepository.locationOriginSettings?.usesFixedReference,
          isTrue,
        );
        expect(
          outsideTenantMaxRepository.locationOriginSettings?.reason,
          LocationOriginReason.outsideRange,
        );

        outsideTenantMaxController.onDispose();
      },
    );

    test(
      'reuses cached fixed reference origin across controller instances after outside-range classification',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final sharedScheduleRepository = _FakeScheduleRepository();
        final locationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(
            CityCoordinate(
              latitudeValue: LatitudeValue()..parse('-23.550520'),
              longitudeValue: LongitudeValue()..parse('-46.633308'),
            ),
          );

        final firstController = _buildAgendaController(
          scheduleRepository: sharedScheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
        );

        await firstController.init();
        expect(sharedScheduleRepository.getEventsPageCallCount, 1);
        firstController.onDispose();

        final secondController = _buildAgendaController(
          scheduleRepository: sharedScheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
        );

        await secondController.init();

        expect(
          sharedScheduleRepository.getEventsPageCallCount,
          1,
          reason:
              'Persisted fixed-reference mode must hydrate the same Home cache on re-entry.',
        );

        secondController.onDispose();
      },
    );

    test('uses tenant default origin when cached user location is stale',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-23.550520'),
            longitudeValue: LongitudeValue()..parse('-46.633308'),
          ),
        )
        ..lastKnownCapturedAtStreamValue.addValue(
          DateTime.now().subtract(const Duration(hours: 2)),
        );

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(scheduleRepository.lastOriginLat, closeTo(-20.671339, 0.000001));
      expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));

      controller.onDispose();
    });

    test('uses tenant default origin when map_ui default origin is flattened',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
        flattenDefaultOrigin: true,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false;

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(scheduleRepository.lastOriginLat, closeTo(-20.671339, 0.000001));
      expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));

      controller.onDispose();
    });

    test(
        'fetches without geo when neither user location nor tenant default exists',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
        includeDefaultOrigin: false,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false;

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(scheduleRepository.lastOriginLat, isNull);
      expect(scheduleRepository.lastOriginLng, isNull);
      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(_displayedEvents(controller), isEmpty);
      expect(controller.hasMoreStreamValue.value, isFalse);

      controller.onDispose();
    });

    test('requests location permission once when warm-up has no coordinate',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false;

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(locationRepository.resolveUserLocationCallCount, 1);
      expect(scheduleRepository.getEventsPageCallCount, 1);

      await controller.searchEvents('');
      expect(locationRepository.resolveUserLocationCallCount, 1);

      controller.onDispose();
    });

    test(
        'does not request location permission when user coordinate already exists',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(locationRepository.resolveUserLocationCallCount, 0);
      expect(scheduleRepository.getEventsPageCallCount, 1);

      controller.onDispose();
    });

    test('ignores location updates below 1km for auto refresh', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(scheduleRepository.getEventsPageCallCount, 1);

      locationRepository.userLocationStreamValue.addValue(
        CityCoordinate(
          latitudeValue: LatitudeValue()..parse('-20.668339'),
          longitudeValue: LongitudeValue()..parse('-40.495395'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(scheduleRepository.getEventsPageCallCount, 1);

      controller.onDispose();
    });

    test('auto refreshes agenda when location jump is at least 1km', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(scheduleRepository.getEventsPageCallCount, 1);

      locationRepository.userLocationStreamValue.addValue(
        CityCoordinate(
          latitudeValue: LatitudeValue()..parse('-20.656339'),
          longitudeValue: LongitudeValue()..parse('-40.495395'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(scheduleRepository.getEventsPageCallCount, 2);
      expect(scheduleRepository.lastOriginLat, closeTo(-20.656339, 0.000001));
      expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));

      controller.onDispose();
    });

    test(
      'auto refresh does not publish transient empty agenda before recovered first page',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final locationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(
            CityCoordinate(
              latitudeValue: LatitudeValue()..parse('-20.671339'),
              longitudeValue: LongitudeValue()..parse('-40.495395'),
            ),
          );
        final backend = _TransientEmptyThenFreshDataBackend();
        final controller = _buildAgendaController(
          scheduleRepository: ScheduleRepository(backend: backend),
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
        );

        await controller.init();
        expect(_displayedEvents(controller), hasLength(1));
        expect(
          _displayedEvents(controller)!.first.title.value,
          'Evento Inicial',
        );

        final publishedTitles = <List<String>?>[
          _displayedEvents(controller)
              ?.map((event) => event.title.value)
              .toList(growable: false),
        ];
        final subscription =
            controller.displayStateStreamValue.stream.listen((displayState) {
          publishedTitles.add(
            displayState?.events
                .map((event) => event.title.value)
                .toList(growable: false),
          );
        });

        locationRepository.userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.656339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 420));

        expect(backend.fetchEventsPageCallCount, 3);
        expect(
          _displayedEvents(controller)?.map((e) => e.title.value),
          ['Evento Atualizado'],
        );
        expect(
          publishedTitles.any((titles) => titles != null && titles.isEmpty),
          isFalse,
          reason:
              'Auto refresh must not publish an empty agenda between non-empty snapshots.',
        );

        await subscription.cancel();
        controller.onDispose();
      },
    );

    test(
      'invite filter does not mutate canonical home agenda stream',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final scheduleRepository = _FakeScheduleRepository();
        final initialEvent = EventDTO.fromJson({
          'event_id': '507f1f77bcf86cd799439511',
          'occurrence_id': '507f1f77bcf86cd799439512',
          'slug': 'evento-canonico',
          'title': 'Evento Canonico',
          'content': 'Conteudo',
          'type': {
            'id': 'type-1',
            'name': 'Show',
            'slug': 'show',
            'description': null,
          },
          'location': {
            'mode': 'physical',
            'display_name': 'Praia do Morro',
            'geo': {
              'type': 'Point',
              'coordinates': [-40.495395, -20.671339],
            },
          },
          'date_time_start': '2026-03-06T20:00:00+00:00',
          'artists': const [],
          'tags': const ['music'],
        }).toDomain();
        scheduleRepository.writeHomeAgendaCache(
          events: <EventModel>[initialEvent],
          hasMore: false,
          maxDistanceMeters: appDataRepository.appData.mapRadiusDefaultMeters,
          originLat: appDataRepository.appData.tenantDefaultOrigin?.latitude,
          originLng: appDataRepository.appData.tenantDefaultOrigin?.longitude,
        );

        final controller = _buildAgendaController(
          scheduleRepository: scheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: appDataRepository,
        );

        await controller.init();
        controller.setInviteFilter(InviteFilter.confirmedOnly);

        expect(_displayedEvents(controller), isEmpty);
        expect(
          scheduleRepository.homeAgendaStreamValue.value
              ?.map((event) => event.title.value),
          <String>['Evento Canonico'],
          reason:
              'Controller-local invite filtering must not rewrite repository-owned Home agenda state.',
        );

        controller.onDispose();
      },
    );

    test(
      'generic paged events queries do not overwrite the canonical home agenda stream',
      () async {
        final appData = _buildAppData(
          minKm: 1,
          defaultKm: 5,
          maxKm: 10,
        );
        final appDataRepository = _FakeAppDataRepository(appData);
        final locationRepository = _FakeUserLocationRepository()
          ..userLocationStreamValue.addValue(
            CityCoordinate(
              latitudeValue: LatitudeValue()..parse('-20.671339'),
              longitudeValue: LongitudeValue()..parse('-40.495395'),
            ),
          );
        final backend = _HomeVsGenericPagedBackend();
        final sharedRepository = ScheduleRepository(backend: backend);

        final controller = _buildAgendaController(
          scheduleRepository: sharedRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: locationRepository,
          appDataRepository: appDataRepository,
        );

        await controller.init();
        expect(
          _displayedEvents(controller)?.map((e) => e.title.value),
          <String>['Evento Home'],
        );

        await sharedRepository.loadEventSearch(
          showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
          searchQuery: ScheduleRepoString.fromRaw('busca', defaultValue: ''),
          confirmedOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
          originLat: ScheduleRepoDouble.fromRaw(-20.671339, defaultValue: 0),
          originLng: ScheduleRepoDouble.fromRaw(-40.495395, defaultValue: 0),
          maxDistanceMeters:
              ScheduleRepoDouble.fromRaw(50000, defaultValue: 50000),
        );

        expect(
          sharedRepository.homeAgendaStreamValue.value
              ?.map((event) => event.title.value),
          <String>['Evento Home'],
          reason:
              'Generic paged scratch state from another query must not replace Home canonical state.',
        );
        expect(
          _displayedEvents(controller)?.map((e) => e.title.value),
          <String>['Evento Home'],
        );

        controller.onDispose();
      },
    );

    test('finishes init when location warm-up stalls', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..neverCompleteWarmUp = true;

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
        locationWarmUpTimeout: const Duration(milliseconds: 20),
        locationPermissionTimeout: const Duration(milliseconds: 20),
      );

      await controller.init();

      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(scheduleRepository.lastOriginLat, closeTo(-20.671339, 0.000001));
      expect(scheduleRepository.lastOriginLng, closeTo(-40.495395, 0.000001));

      controller.onDispose();
    });

    test('continues init when confirmed event refresh fails', () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final locationRepository = _FakeUserLocationRepository()
        ..warmUpResult = false;
      final userEventsRepository = _FakeUserEventsRepository()
        ..throwOnRefreshConfirmedIds = true;

      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: userEventsRepository,
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(scheduleRepository.getEventsPageCallCount, 1);

      controller.onDispose();
    });

    test('does not log refresh failure after controller is disposed mid-fetch',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FailAfterDisposeScheduleRepository();
      final controller = _buildAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      final messages = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          messages.add(message);
        }
      };

      try {
        final initFuture = controller.init();
        await Future<void>.delayed(Duration.zero);
        controller.onDispose();
        scheduleRepository.releaseFailure();
        await initFuture;
      } finally {
        debugPrint = originalDebugPrint;
      }

      expect(
        messages.where((message) => message.contains('_refresh failed')),
        isEmpty,
      );
      expect(
        messages.where(
          (message) =>
              message.contains('_refresh retry failed after first-page error'),
        ),
        isEmpty,
      );
    });

    test(
        'renders event from canonical agenda payload when type.id is non-ObjectId',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );

      final controller = _buildAgendaController(
        scheduleRepository: ScheduleRepository(
          backend: _PayloadScheduleBackend(),
        ),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(_displayedEvents(controller), hasLength(1));
      final event = _displayedEvents(controller)!.first;
      expect(event.type.id.value, 'type-1');
      expect(event.coordinate, isNotNull);
      expect(event.coordinate!.latitude, closeTo(-20.671339, 0.000001));
      expect(event.coordinate!.longitude, closeTo(-40.495395, 0.000001));
      expect(event.artists.single.avatarUri, isNull);

      controller.onDispose();
    });

    test('does not auto-page when current filter leaves first page empty',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );
      final backend = _AutoPageRegressionBackend();
      final controller = _buildAgendaController(
        scheduleRepository: ScheduleRepository(backend: backend),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(backend.requestedPages, [1]);

      controller.setInviteFilter(InviteFilter.confirmedOnly);

      expect(_displayedEvents(controller), isEmpty);
      expect(backend.requestedPages, [1]);

      controller.onDispose();
    });

    testWidgets('home agenda body does not load next page on initial build',
        (tester) async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final locationRepository = _FakeUserLocationRepository()
        ..userLocationStreamValue.addValue(
          CityCoordinate(
            latitudeValue: LatitudeValue()..parse('-20.671339'),
            longitudeValue: LongitudeValue()..parse('-40.495395'),
          ),
        );
      final backend = _AutoPageRegressionBackend();
      final controller = _buildAgendaController(
        scheduleRepository: ScheduleRepository(backend: backend),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(backend.requestedPages, [1]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeAgendaBody(controller: controller),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(backend.requestedPages, [1]);

      controller.onDispose();
    });

    test('home agenda compact-state setter publishes only real changes', () {
      final controller = _buildAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(
          _buildAppData(
            minKm: 1,
            defaultKm: 5,
            maxKm: 10,
          ),
        ),
      );

      expect(controller.isRadiusActionCompactStreamValue.value, isFalse);

      controller.setRadiusActionCompactState(true);
      expect(controller.isRadiusActionCompactStreamValue.value, isTrue);

      controller.setRadiusActionCompactState(true);
      expect(controller.isRadiusActionCompactStreamValue.value, isTrue);

      controller.setRadiusActionCompactState(false);
      expect(controller.isRadiusActionCompactStreamValue.value, isFalse);

      controller.onDispose();
    });

    test('home agenda compact state follows first non-zero scroll offset', () {
      final controller = _buildAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(
          _buildAppData(
            minKm: 1,
            defaultKm: 5,
            maxKm: 10,
          ),
        ),
      );

      expect(controller.isRadiusActionCompactStreamValue.value, isFalse);

      controller.updateRadiusActionCompactStateFromScroll(1);
      expect(controller.isRadiusActionCompactStreamValue.value, isTrue);

      controller.updateRadiusActionCompactStateFromScroll(0.6);
      expect(controller.isRadiusActionCompactStreamValue.value, isTrue);

      controller.updateRadiusActionCompactStateFromScroll(0);
      expect(controller.isRadiusActionCompactStreamValue.value, isFalse);

      controller.onDispose();
    });

    testWidgets(
      'home shell scroll compacts radius action before inner list scroll starts',
      (tester) async {
        final controller = _buildAgendaController(
          scheduleRepository: ScheduleRepository(
            backend: _ScrollableAgendaBackend(),
          ),
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: _FakeAppDataRepository(
            _buildAppData(
              minKm: 1,
              defaultKm: 5,
              maxKm: 10,
            ),
          ),
        );
        final shellScrollController = ScrollController();

        addTearDown(controller.onDispose);
        addTearDown(shellScrollController.dispose);

        await controller.init();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeAgendaSectionView(
                controller: controller,
                scrollController: shellScrollController,
                builder: (context, slots) {
                  return NestedScrollView(
                    controller: shellScrollController,
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 240),
                      ),
                      slots.header as SliverPersistentHeader,
                    ],
                    body: slots.body,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('agenda-radius-expanded')),
          findsOneWidget,
        );
        expect(controller.isRadiusActionCompactStreamValue.value, isFalse);

        await tester.drag(find.byType(ListView), const Offset(0, -80));
        await tester.pumpAndSettle();

        expect(
          shellScrollController.offset,
          greaterThan(0),
        );
        expect(
          find.byKey(const ValueKey<String>('agenda-radius-compact')),
          findsOneWidget,
        );
        expect(controller.isRadiusActionCompactStreamValue.value, isTrue);

        await tester.fling(find.byType(ListView), const Offset(0, 400), 2000);
        await tester.pumpAndSettle();

        expect(shellScrollController.offset, 0);
        expect(
          find.byKey(const ValueKey<String>('agenda-radius-expanded')),
          findsOneWidget,
        );
        expect(controller.isRadiusActionCompactStreamValue.value, isFalse);
      },
    );

    testWidgets(
      'home nested inner agenda scroll keeps radius action compact and restores at top',
      (tester) async {
        final controller = _buildAgendaController(
          scheduleRepository: ScheduleRepository(
            backend: _ScrollableAgendaBackend(),
          ),
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: _FakeAppDataRepository(
            _buildAppData(
              minKm: 1,
              defaultKm: 5,
              maxKm: 10,
            ),
          ),
        );
        final shellScrollController = ScrollController();

        addTearDown(controller.onDispose);
        addTearDown(shellScrollController.dispose);

        await controller.init();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeAgendaSectionView(
                controller: controller,
                scrollController: shellScrollController,
                builder: (context, slots) {
                  return NestedScrollView(
                    controller: shellScrollController,
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      slots.header as SliverPersistentHeader,
                    ],
                    body: slots.body,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('agenda-radius-expanded')),
          findsOneWidget,
        );
        expect(
          controller.isRadiusActionCompactStreamValue.value,
          isFalse,
        );

        await tester.drag(find.byType(ListView), const Offset(0, -900));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('agenda-radius-compact')),
          findsOneWidget,
        );
        expect(
          controller.isRadiusActionCompactStreamValue.value,
          isTrue,
        );

        await tester.fling(find.byType(ListView), const Offset(0, 1400), 4000);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('agenda-radius-expanded')),
          findsOneWidget,
        );
        expect(
          controller.isRadiusActionCompactStreamValue.value,
          isFalse,
        );
      },
    );

    testWidgets('home agenda body shows phased initial loading labels',
        (tester) async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final controller = _buildAgendaController(
        scheduleRepository: _FakeScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: _FakeAppDataRepository(appData),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeAgendaBody(controller: controller),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Encontrando sua localização...'), findsOneWidget);

      controller.initialLoadingLabelStreamValue
          .addValue('Buscando eventos perto de você...');
      await tester.pump();

      expect(find.text('Buscando eventos perto de você...'), findsOneWidget);

      controller.onDispose();
    });

    testWidgets(
      'home agenda section re-syncs compact state after outer controller attaches',
      (tester) async {
        final controller = _buildAgendaController(
          scheduleRepository: ScheduleRepository(
            backend: _ScrollableAgendaBackend(),
          ),
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: _FakeAppDataRepository(
            _buildAppData(
              minKm: 1,
              defaultKm: 5,
              maxKm: 10,
            ),
          ),
        );
        final outerScrollController = _DeferredAttachScrollController();

        addTearDown(controller.onDispose);
        addTearDown(outerScrollController.dispose);

        await controller.init();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          outerScrollController.attachWithOffset(48);
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeAgendaSectionView(
                controller: controller,
                scrollController: outerScrollController,
                builder: (context, slots) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          controller.isRadiusActionCompactStreamValue.value,
          isTrue,
        );
      },
    );

    testWidgets(
      'home agenda section re-syncs compact state when outer controller restores offset late without scroll notification',
      (tester) async {
        final controller = _buildAgendaController(
          scheduleRepository: ScheduleRepository(
            backend: _ScrollableAgendaBackend(),
          ),
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: _FakeAppDataRepository(
            _buildAppData(
              minKm: 1,
              defaultKm: 5,
              maxKm: 10,
            ),
          ),
        );
        final outerScrollController = _DeferredAttachScrollController();

        addTearDown(controller.onDispose);
        addTearDown(outerScrollController.dispose);

        await controller.init();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              outerScrollController.setAttachedState(
                hasClients: true,
                offset: 48,
              );
            });
          });
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeAgendaSectionView(
                controller: controller,
                scrollController: outerScrollController,
                builder: (context, slots) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          controller.isRadiusActionCompactStreamValue.value,
          isTrue,
        );
      },
    );
  });
}

class _DeferredAttachScrollController extends ScrollController {
  bool _hasAttachedClients = false;
  double _attachedOffset = 0;

  @override
  bool get hasClients => _hasAttachedClients;

  @override
  double get offset => _attachedOffset;

  void attachWithOffset(double offset) {
    _hasAttachedClients = true;
    _attachedOffset = offset;
    notifyListeners();
  }

  void setAttachedState({
    required bool hasClients,
    required double offset,
    bool notify = false,
  }) {
    _hasAttachedClients = hasClients;
    _attachedOffset = offset;
    if (notify) {
      notifyListeners();
    }
  }
}

TenantHomeAgendaController _buildAgendaController({
  required ScheduleRepositoryContract scheduleRepository,
  required UserEventsRepositoryContract userEventsRepository,
  required InvitesRepositoryContract invitesRepository,
  required UserLocationRepositoryContract? userLocationRepository,
  required AppDataRepositoryContract appDataRepository,
  AuthRepositoryContract? authRepository,
  bool? isWebRuntime,
  Duration? locationWarmUpTimeout,
  Duration? locationPermissionTimeout,
  Duration? radiusRefreshDebounce,
}) {
  return TenantHomeAgendaController(
    scheduleRepository: scheduleRepository,
    userEventsRepository: userEventsRepository,
    invitesRepository: invitesRepository,
    userLocationRepository: userLocationRepository,
    appDataRepository: appDataRepository,
    authRepository: authRepository,
    locationOriginService: LocationOriginService(
      appDataRepository: appDataRepository,
      userLocationRepository: userLocationRepository,
    ),
    isWebRuntime: isWebRuntime ?? true,
    locationWarmUpTimeout: locationWarmUpTimeout ?? const Duration(seconds: 4),
    locationPermissionTimeout:
        locationPermissionTimeout ?? const Duration(seconds: 8),
    radiusRefreshDebounce:
        radiusRefreshDebounce ?? const Duration(milliseconds: 250),
  );
}

AppData _buildAppData({
  required num minKm,
  required num defaultKm,
  required num maxKm,
  bool includeDefaultOrigin = true,
  bool flattenDefaultOrigin = false,
}) {
  final mapUi = <String, dynamic>{
    'radius': {
      'min_km': minKm,
      'default_km': defaultKm,
      'max_km': maxKm,
    },
  };
  if (includeDefaultOrigin) {
    if (flattenDefaultOrigin) {
      mapUi['default_origin.lat'] = -20.671339;
      mapUi['default_origin.lng'] = -40.495395;
      mapUi['default_origin.label'] = 'Praia do Morro';
    } else {
      mapUi['default_origin'] = const {
        'lat': -20.671339,
        'lng': -40.495395,
        'label': 'Praia do Morro',
      };
    }
  }

  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
    'settings': {
      'map_ui': mapUi,
    },
  };

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };

  return buildAppDataFromInitialization(
      remoteData: remoteData, localInfo: localInfo);
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(
    this._appData, {
    double? initialMaxRadiusMeters,
    bool hasPersistedMaxRadiusPreference = false,
  })  : _hasPersistedMaxRadiusPreference = hasPersistedMaxRadiusPreference,
        maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
          defaultValue: DistanceInMetersValue.fromRaw(
            initialMaxRadiusMeters ?? _appData.mapRadiusMaxMeters,
            defaultValue: initialMaxRadiusMeters ?? _appData.mapRadiusMaxMeters,
          ),
        );

  final AppData _appData;
  bool _hasPersistedMaxRadiusPreference;
  int setMaxRadiusMetersCallCount = 0;
  int setLocationOriginSettingsCallCount = 0;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    setMaxRadiusMetersCallCount += 1;
    _hasPersistedMaxRadiusPreference = true;
    maxRadiusMetersStreamValue.addValue(meters);
  }

  @override
  Future<void> setLocationOriginSettings(
    LocationOriginSettings settings,
  ) async {
    final current = locationOriginSettingsStreamValue.value;
    if (current != null && current.sameAs(settings)) {
      return;
    }
    setLocationOriginSettingsCallCount += 1;
    locationOriginSettingsStreamValue.addValue(settings);
  }

  @override
  bool get hasPersistedMaxRadiusPreference => _hasPersistedMaxRadiusPreference;
}

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  @override
  final StreamValue<List<EventModel>?> homeAgendaStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<List<EventModel>?> discoveryLiveNowEventsStreamValue =
      StreamValue<List<EventModel>?>(defaultValue: null);

  int getEventsPageCallCount = 0;
  double? lastOriginLat;
  double? lastOriginLng;
  Completer<void>? nextFetchGate;
  _FakeHomeAgendaState? _homeAgendaState;

  @override
  List<EventModel>? readHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final state = _resolveHomeAgendaState(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    return state?.events;
  }

  _FakeHomeAgendaState? _resolveHomeAgendaState({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) {
    final state = _homeAgendaState;
    if (state == null) return null;
    if (state.showPastOnly != showPastOnly.value) return null;
    if (state.searchQuery != searchQuery.value) return null;
    if (state.confirmedOnly != confirmedOnly.value) return null;
    if (state.originLat != originLat?.value) return null;
    if (state.originLng != originLng?.value) return null;
    if (state.maxDistanceMeters != maxDistanceMeters?.value) return null;
    return state;
  }

  void writeHomeAgendaCache({
    required List<EventModel> events,
    required bool hasMore,
    int nextPage = 2,
    bool showPastOnly = false,
    String searchQuery = '',
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) {
    final materialized = List<EventModel>.unmodifiable(events);
    _homeAgendaState = _FakeHomeAgendaState(
      events: materialized,
      nextPage: nextPage,
      hasMore: hasMore,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    homeAgendaStreamValue.addValue(materialized);
  }

  void clearHomeAgendaCache() {
    _homeAgendaState = null;
    homeAgendaStreamValue.addValue(null);
  }

  @override
  Future<List<EventModel>> loadHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final events = await _fetchPage(
      page: 1,
      pageSize: 25,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    writeHomeAgendaCache(
      events: events,
      hasMore: events.length >= 25,
      nextPage: 2,
      showPastOnly: showPastOnly.value,
      searchQuery: searchQuery.value,
      confirmedOnly: confirmedOnly.value,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );
    return events;
  }

  @override
  Future<List<EventModel>> loadMoreHomeAgenda({
    required ScheduleRepoBool showPastOnly,
    required ScheduleRepoString searchQuery,
    required ScheduleRepoBool confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final current = _resolveHomeAgendaState(
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    if (current != null && !current.hasMore) {
      return current.events;
    }
    final nextPage = current?.nextPage ?? 1;
    final events = await _fetchPage(
      page: nextPage,
      pageSize: 25,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final nextEvents = <EventModel>[
      ...?current?.events,
      ...events,
    ];
    writeHomeAgendaCache(
      events: nextEvents,
      hasMore: events.length >= 25,
      nextPage: nextPage + 1,
      showPastOnly: showPastOnly.value,
      searchQuery: searchQuery.value,
      confirmedOnly: confirmedOnly.value,
      originLat: originLat?.value,
      originLng: originLng?.value,
      maxDistanceMeters: maxDistanceMeters?.value,
    );
    return nextEvents;
  }

  @override
  Future<EventModel?> getEventBySlug(ScheduleRepoString slug) async => null;

  Future<List<EventModel>> _fetchPage({
    required int page,
    required int pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    lastOriginLat = originLat?.value;
    lastOriginLng = originLng?.value;
    final fetchGate = nextFetchGate;
    if (fetchGate != null) {
      nextFetchGate = null;
      await fetchGate.future;
    }
    return const <EventModel>[];
  }

  @override
  Future<List<EventModel>> loadEventSearch({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async =>
      _fetchPage(
        page: 1,
        pageSize: 25,
        showPastOnly: showPastOnly,
        searchQuery: searchQuery,
        confirmedOnly: confirmedOnly,
        originLat: originLat,
        originLng: originLng,
        maxDistanceMeters: maxDistanceMeters,
      );

  @override
  Future<List<EventModel>> loadMoreEventSearch({
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async =>
      const <EventModel>[];

  @override
  Future<List<EventModel>> loadConfirmedEvents({
    required ScheduleRepoBool showPastOnly,
  }) async =>
      const <EventModel>[];

  @override
  Future<void> refreshDiscoveryLiveNowEvents({
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    final events = await _fetchPage(
      page: 1,
      pageSize: 10,
      showPastOnly: ScheduleRepoBool.fromRaw(false, defaultValue: false),
      liveNowOnly: ScheduleRepoBool.fromRaw(true, defaultValue: true),
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    discoveryLiveNowEventsStreamValue.addValue(events);
  }

  @override
  Stream<EventDeltaModel> watchEventsStream({
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return const Stream<EventDeltaModel>.empty();
  }

  @override
  Stream<void> watchEventsSignal({
    required ScheduleRepositoryContractDeltaHandler onDelta,
    ScheduleRepoString? searchQuery,
    List<ScheduleRepoString>? categories,
    List<ScheduleRepoString>? tags,
    ScheduleRepoTaxonomyEntries? taxonomy,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
    ScheduleRepoString? lastEventId,
    ScheduleRepoBool? showPastOnly,
  }) {
    return watchEventsStream(
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
      lastEventId: lastEventId,
      showPastOnly: showPastOnly,
    ).map((delta) {
      onDelta(delta);
    });
  }
}

class _FakeHomeAgendaState {
  const _FakeHomeAgendaState({
    required this.events,
    required this.nextPage,
    required this.hasMore,
    required this.showPastOnly,
    required this.searchQuery,
    required this.confirmedOnly,
    required this.originLat,
    required this.originLng,
    required this.maxDistanceMeters,
  });

  final List<EventModel> events;
  final int nextPage;
  final bool hasMore;
  final bool showPastOnly;
  final String searchQuery;
  final bool confirmedOnly;
  final double? originLat;
  final double? originLng;
  final double? maxDistanceMeters;
}

class _FailingScheduleRepository extends _FakeScheduleRepository {
  @override
  Future<List<EventModel>> _fetchPage({
    required int page,
    required int pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    throw Exception('forced first-page failure');
  }
}

class _FailingOnceScheduleRepository extends _FakeScheduleRepository {
  bool _failed = false;

  @override
  Future<List<EventModel>> _fetchPage({
    required int page,
    required int pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    lastOriginLat = originLat?.value;
    lastOriginLng = originLng?.value;

    if (!_failed) {
      _failed = true;
      throw Exception('forced transient first-page failure');
    }

    return const <EventModel>[];
  }
}

class _AlwaysFailingScheduleRepository extends _FakeScheduleRepository {
  @override
  Future<List<EventModel>> _fetchPage({
    required int page,
    required int pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    throw Exception('forced persistent first-page failure');
  }
}

class _FailAfterDisposeScheduleRepository extends _FakeScheduleRepository {
  final Completer<void> _failureGate = Completer<void>();

  void releaseFailure() {
    if (!_failureGate.isCompleted) {
      _failureGate.complete();
    }
  }

  @override
  Future<List<EventModel>> _fetchPage({
    required int page,
    required int pageSize,
    required ScheduleRepoBool showPastOnly,
    ScheduleRepoString? searchQuery,
    ScheduleRepoBool? confirmedOnly,
    ScheduleRepoBool? liveNowOnly,
    ScheduleRepoDouble? originLat,
    ScheduleRepoDouble? originLng,
    ScheduleRepoDouble? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    await _failureGate.future;
    throw Exception('forced disposed refresh failure');
  }
}

class _PayloadScheduleBackend implements ScheduleBackendContract {
  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      _eventDto();

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    if (page > 1) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    return EventPageDTO(
      events: [_eventDto()],
      hasMore: false,
    );
  }

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) =>
      const Stream<EventDeltaDTO>.empty();

  EventDTO _eventDto() {
    return EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439011',
      'occurrence_id': '507f1f77bcf86cd799439012',
      'slug': 'evento-teste',
      'title': 'Evento Teste',
      'content': 'Conteudo do evento',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': null,
        'color': '#112233',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-03T20:00:00+00:00',
      'artists': const [
        {
          'id': '507f1f77bcf86cd799439013',
          'name': 'Main Artist',
          'avatar_url': null,
          'genres': ['rock'],
        },
      ],
      'tags': const ['music'],
    });
  }
}

class _AutoPageRegressionBackend implements ScheduleBackendContract {
  final List<int> requestedPages = <int>[];

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      _pageOneEvent();

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    requestedPages.add(page);
    if (page == 1) {
      return EventPageDTO(
        events: [_pageOneEvent()],
        hasMore: true,
      );
    }

    return EventPageDTO(
      events: [_pageTwoEvent()],
      hasMore: false,
    );
  }

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) =>
      const Stream<EventDeltaDTO>.empty();

  EventDTO _pageOneEvent() {
    return EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439111',
      'occurrence_id': '507f1f77bcf86cd799439112',
      'slug': 'pagina-um',
      'title': 'Pagina Um',
      'content': 'Conteudo',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-03T20:00:00+00:00',
      'artists': const [],
      'tags': const ['music'],
    });
  }

  EventDTO _pageTwoEvent() {
    return EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439121',
      'occurrence_id': '507f1f77bcf86cd799439122',
      'slug': 'pagina-dois',
      'title': 'Pagina Dois',
      'content': 'Conteudo',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-04T20:00:00+00:00',
      'artists': const [],
      'tags': const ['music'],
    });
  }
}

class _ScrollableAgendaBackend implements ScheduleBackendContract {
  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      _eventDto(index: 0);

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    if (page > 1) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    return EventPageDTO(
      events: List<EventDTO>.generate(
        14,
        (index) => _eventDto(index: index),
      ),
      hasMore: false,
    );
  }

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) =>
      const Stream<EventDeltaDTO>.empty();

  EventDTO _eventDto({required int index}) {
    final day = (index % 14) + 1;
    final hour = 18 + (index % 4);

    return EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd7994398${index.toString().padLeft(2, '0')}',
      'occurrence_id':
          '507f1f77bcf86cd7994399${index.toString().padLeft(2, '0')}',
      'slug': 'evento-scroll-$index',
      'title': 'Evento Scroll $index',
      'content': 'Conteudo $index',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start':
          '2026-03-${day.toString().padLeft(2, '0')}T${hour.toString().padLeft(2, '0')}:00:00+00:00',
      'artists': const [],
      'tags': const ['music'],
    });
  }
}

class _CountingPayloadScheduleBackend extends _PayloadScheduleBackend {
  int fetchEventsPageCallCount = 0;

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    fetchEventsPageCallCount += 1;
    return super.fetchEventsPage(
      page: page,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
      liveNowOnly: liveNowOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
  }
}

class _HomeVsGenericPagedBackend implements ScheduleBackendContract {
  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      _eventDto(
        eventId: '507f1f77bcf86cd799439411',
        occurrenceId: '507f1f77bcf86cd799439412',
        slug: 'evento-home',
        title: 'Evento Home',
      );

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    if (page > 1) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    if ((searchQuery ?? '').trim() == 'busca') {
      return EventPageDTO(
        events: [
          _eventDto(
            eventId: '507f1f77bcf86cd799439421',
            occurrenceId: '507f1f77bcf86cd799439422',
            slug: 'evento-busca',
            title: 'Evento Busca',
          ),
        ],
        hasMore: false,
      );
    }

    return EventPageDTO(
      events: [
        _eventDto(
          eventId: '507f1f77bcf86cd799439411',
          occurrenceId: '507f1f77bcf86cd799439412',
          slug: 'evento-home',
          title: 'Evento Home',
        ),
      ],
      hasMore: false,
    );
  }

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) =>
      const Stream<EventDeltaDTO>.empty();

  EventDTO _eventDto({
    required String eventId,
    required String occurrenceId,
    required String slug,
    required String title,
  }) {
    return EventDTO.fromJson({
      'event_id': eventId,
      'occurrence_id': occurrenceId,
      'slug': slug,
      'title': title,
      'content': 'Conteudo',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-06T20:00:00+00:00',
      'artists': const [],
      'tags': const ['music'],
    });
  }
}

class _FailingOnceThenDataBackend implements ScheduleBackendContract {
  int fetchEventsPageCallCount = 0;

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      _eventDto();

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    fetchEventsPageCallCount += 1;

    if (fetchEventsPageCallCount == 1) {
      throw Exception('forced transient first-page failure');
    }

    if (page > 1) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    return EventPageDTO(events: [_eventDto()], hasMore: false);
  }

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) =>
      const Stream<EventDeltaDTO>.empty();

  EventDTO _eventDto() {
    return EventDTO.fromJson({
      'event_id': '507f1f77bcf86cd799439211',
      'occurrence_id': '507f1f77bcf86cd799439212',
      'slug': 'evento-recuperado',
      'title': 'Evento Recuperado',
      'content': 'Conteudo do evento recuperado',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
        'color': '#112233',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-05T20:00:00+00:00',
      'artists': const [],
      'tags': const ['music'],
    });
  }
}

class _TransientEmptyThenFreshDataBackend implements ScheduleBackendContract {
  int fetchEventsPageCallCount = 0;

  @override
  Future<EventDTO?> fetchEventDetail({required String eventIdOrSlug}) async =>
      _eventDto(
        eventId: '507f1f77bcf86cd799439311',
        occurrenceId: '507f1f77bcf86cd799439312',
        slug: 'evento-inicial',
        title: 'Evento Inicial',
      );

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    fetchEventsPageCallCount += 1;

    if (page > 1) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    if (fetchEventsPageCallCount == 1) {
      return EventPageDTO(
        events: [
          _eventDto(
            eventId: '507f1f77bcf86cd799439311',
            occurrenceId: '507f1f77bcf86cd799439312',
            slug: 'evento-inicial',
            title: 'Evento Inicial',
          ),
        ],
        hasMore: false,
      );
    }

    if (fetchEventsPageCallCount == 2) {
      return EventPageDTO(events: const [], hasMore: false);
    }

    return EventPageDTO(
      events: [
        _eventDto(
          eventId: '507f1f77bcf86cd799439321',
          occurrenceId: '507f1f77bcf86cd799439322',
          slug: 'evento-atualizado',
          title: 'Evento Atualizado',
        ),
      ],
      hasMore: false,
    );
  }

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) =>
      const Stream<EventDeltaDTO>.empty();

  EventDTO _eventDto({
    required String eventId,
    required String occurrenceId,
    required String slug,
    required String title,
  }) {
    return EventDTO.fromJson({
      'event_id': eventId,
      'occurrence_id': occurrenceId,
      'slug': slug,
      'title': title,
      'content': 'Conteudo do evento',
      'type': {
        'id': 'type-1',
        'name': 'Show',
        'slug': 'show',
        'description': 'Show type description',
        'color': '#112233',
      },
      'location': {
        'mode': 'physical',
        'display_name': 'Praia do Morro',
        'geo': {
          'type': 'Point',
          'coordinates': [-40.495395, -20.671339],
        },
      },
      'date_time_start': '2026-03-05T20:00:00+00:00',
      'artists': const [],
      'tags': const ['music'],
    });
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  Future<List<InviteModel>> fetchInvites(
          {InvitesRepositoryContractPrimInt? page,
          InvitesRepositoryContractPrimInt? pageSize}) async =>
      const [];

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(
          InvitesRepositoryContractPrimString inviteId) async =>
      buildInviteAcceptResult(
        inviteId: inviteId.value,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
          InvitesRepositoryContractPrimString code) async =>
      buildInviteAcceptResult(
        inviteId: 'mock-${code.value}',
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(
          InvitesRepositoryContractPrimString inviteId) async =>
      buildInviteDeclineResult(
        inviteId: inviteId.value,
        status: 'declined',
        groupHasOtherPending: false,
      );
  @override
  Future<List<InviteContactMatch>> importContacts(
          InviteContacts contacts) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async =>
      buildInviteShareCodeResult(
        code: 'CODE123',
        eventId: eventId.value,
        occurrenceId: occurrenceId?.value,
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      InvitesRepositoryContractPrimString eventSlug) async {
    return const [];
  }

  @override
  Future<void> sendInvites(InvitesRepositoryContractPrimString eventSlug,
      InviteRecipients recipients,
      {InvitesRepositoryContractPrimString? occurrenceId,
      InvitesRepositoryContractPrimString? message}) async {}
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    required bool authorized,
  }) : _authorized = authorized;

  bool _authorized;

  void setAuthorized(bool value) {
    _authorized = value;
    userStreamValue.addValue(null);
  }

  @override
  Object get backend => throw UnimplementedError();

  @override
  String get userToken => _authorized ? 'token' : '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => _authorized ? 'user-1' : null;

  @override
  bool get isUserLoggedIn => _authorized;

  @override
  bool get isAuthorized => _authorized;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {
    setAuthorized(false);
  }

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  bool throwOnRefreshConfirmedIds = false;

  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
          defaultValue: const {});

  @override
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(false, defaultValue: false, isRequired: true);

  @override
  Future<void> unconfirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {
    if (throwOnRefreshConfirmedIds) {
      throw Exception('forced confirmed ids failure');
    }
  }
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  bool warmUpCalled = false;
  bool warmUpResult = false;
  bool neverCompleteWarmUp = false;
  int resolveUserLocationCallCount = 0;

  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>(defaultValue: null);

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>(defaultValue: null);

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(
    UserLocationRepositoryContractTextValue? address,
  ) async {
    lastKnownAddressStreamValue.addValue(address?.value);
  }

  @override
  Future<bool> warmUpIfPermitted() async {
    warmUpCalled = true;
    if (neverCompleteWarmUp) {
      return Completer<bool>().future;
    }
    return warmUpResult;
  }

  @override
  Future<bool> refreshIfPermitted({
    UserLocationRepositoryContractDurationValue? minInterval,
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async {
    resolveUserLocationCallCount += 1;
    return null;
  }

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      false;

  @override
  Future<void> stopTracking() async {}
}
