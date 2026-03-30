import 'dart:async';
import 'package:belluga_now/testing/domain_factories.dart';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
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
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/paged_events_result.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/repositories/schedule_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/home_agenda_body.dart';
import 'package:belluga_now/presentation/tenant_public/home/screens/tenant_home_screen/widgets/agenda_section/controllers/tenant_home_agenda_controller.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/event_search_screen/models/invite_filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

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
      final controller = TenantHomeAgendaController(
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
      final controller = TenantHomeAgendaController(
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

    test('clamps radius updates to tenant bounds and reacts to max changes',
        () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final controller = TenantHomeAgendaController(
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

      await appDataRepository.setMaxRadiusMeters(5000);
      expect(controller.radiusMetersStreamValue.value, 5000);

      controller.onDispose();
    });

    test('coalesces rapid radius updates into a single refresh', () async {
      final appData = _buildAppData(
        minKm: 2,
        defaultKm: 7,
        maxKm: 15,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _FakeScheduleRepository();
      final controller = TenantHomeAgendaController(
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
      final controller = TenantHomeAgendaController(
        scheduleRepository: _FailingScheduleRepository(),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.displayedEventsStreamValue.value, isNull);

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
      final controller = TenantHomeAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(scheduleRepository.getEventsPageCallCount, 2);
      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.displayedEventsStreamValue.value, isEmpty);

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
      final controller = TenantHomeAgendaController(
        scheduleRepository: ScheduleRepository(backend: backend),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(backend.fetchEventsPageCallCount, 2);
      expect(controller.isInitialLoadingStreamValue.value, isFalse);
      expect(controller.displayedEventsStreamValue.value, hasLength(1));
      expect(
        controller.displayedEventsStreamValue.value!.first.title.value,
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
      final controller = TenantHomeAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(scheduleRepository.getEventsPageCallCount, 1);
      expect(controller.displayedEventsStreamValue.value, isNotNull);

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

        final firstController = TenantHomeAgendaController(
          scheduleRepository: sharedScheduleRepository,
          userEventsRepository: _FakeUserEventsRepository(),
          invitesRepository: _FakeInvitesRepository(),
          userLocationRepository: _FakeUserLocationRepository(),
          appDataRepository: appDataRepository,
        );
        await firstController.init();
        expect(sharedScheduleRepository.getEventsPageCallCount, 1);
        firstController.onDispose();

        final secondController = TenantHomeAgendaController(
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

    test('retries init when previous load ended without cached results',
        () async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final appDataRepository = _FakeAppDataRepository(appData);
      final scheduleRepository = _AlwaysFailingScheduleRepository();
      final controller = TenantHomeAgendaController(
        scheduleRepository: scheduleRepository,
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: _FakeUserLocationRepository(),
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(controller.displayedEventsStreamValue.value, isNull);
      expect(scheduleRepository.getEventsPageCallCount, 2);

      await controller.init();
      expect(
        scheduleRepository.getEventsPageCallCount,
        4,
        reason: 'When cache is null, init must retry fetching.',
      );

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

      final controller = TenantHomeAgendaController(
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

      controller.onDispose();
    });

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

      final controller = TenantHomeAgendaController(
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

      final controller = TenantHomeAgendaController(
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

      final controller = TenantHomeAgendaController(
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
      expect(controller.displayedEventsStreamValue.value, isEmpty);
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

      final controller = TenantHomeAgendaController(
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

      final controller = TenantHomeAgendaController(
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

      final controller = TenantHomeAgendaController(
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

      final controller = TenantHomeAgendaController(
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

      final controller = TenantHomeAgendaController(
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

      final controller = TenantHomeAgendaController(
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

      final controller = TenantHomeAgendaController(
        scheduleRepository: ScheduleRepository(
          backend: _PayloadScheduleBackend(),
        ),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();

      expect(controller.displayedEventsStreamValue.value, hasLength(1));
      final event = controller.displayedEventsStreamValue.value!.first;
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
      final controller = TenantHomeAgendaController(
        scheduleRepository: ScheduleRepository(backend: backend),
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        userLocationRepository: locationRepository,
        appDataRepository: appDataRepository,
      );

      await controller.init();
      expect(backend.requestedPages, [1]);

      controller.setInviteFilter(InviteFilter.confirmedOnly);

      expect(controller.displayedEventsStreamValue.value, isEmpty);
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
      final controller = TenantHomeAgendaController(
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

    testWidgets('home agenda body shows phased initial loading labels',
        (tester) async {
      final appData = _buildAppData(
        minKm: 1,
        defaultKm: 5,
        maxKm: 10,
      );
      final controller = TenantHomeAgendaController(
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
  });
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

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository(
    this._appData, {
    double? initialMaxRadiusMeters,
    bool hasPersistedMaxRadiusPreference = false,
  })  : _hasPersistedMaxRadiusPreference = hasPersistedMaxRadiusPreference,
        maxRadiusMetersStreamValue = StreamValue<double>(
          defaultValue: initialMaxRadiusMeters ?? _appData.mapRadiusMaxMeters,
        );

  final AppData _appData;
  bool _hasPersistedMaxRadiusPreference;

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
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeStreamValue.addValue(mode);
  }

  @override
  final StreamValue<double> maxRadiusMetersStreamValue;

  @override
  double get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  bool get hasPersistedMaxRadiusPreference => _hasPersistedMaxRadiusPreference;

  @override
  Future<void> setMaxRadiusMeters(double meters) async {
    _hasPersistedMaxRadiusPreference = true;
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeScheduleRepository implements ScheduleRepositoryContract {
  @override
  final StreamValue<List<EventModel>?> homeAgendaEventsStreamValue =
      StreamValue<List<EventModel>?>();
  @override
  final StreamValue<HomeAgendaCacheSnapshot?> homeAgendaCacheStreamValue =
      StreamValue<HomeAgendaCacheSnapshot?>();
  @override
  final StreamValue<List<EventModel>> eventSearchDisplayedEventsStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const <EventModel>[]);
  @override
  final StreamValue<List<EventModel>> eventsByDateStreamValue =
      StreamValue<List<EventModel>>(defaultValue: const <EventModel>[]);
  @override
  final StreamValue<PagedEventsResult?> pagedEventsStreamValue =
      StreamValue<PagedEventsResult?>(defaultValue: null);
  @override
  final StreamValue<bool> hasMorePagedEventsStreamValue =
      StreamValue<bool>(defaultValue: true);
  @override
  final StreamValue<bool> isPagedEventsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);
  @override
  final StreamValue<String?> pagedEventsErrorStreamValue =
      StreamValue<String?>(defaultValue: null);

  int getEventsPageCallCount = 0;
  int _currentPagedEventsPage = 0;
  double? lastOriginLat;
  double? lastOriginLng;

  @override
  int get currentPagedEventsPage => _currentPagedEventsPage;

  @override
  HomeAgendaCacheSnapshot? readHomeAgendaCache({
    required bool showPastOnly,
    bool liveNowOnly = false,
    required String searchQuery,
    required bool confirmedOnly,
  }) {
    final snapshot = homeAgendaCacheStreamValue.value;
    if (snapshot == null) return null;
    if (snapshot.showPastOnly != showPastOnly) return null;
    if (snapshot.searchQuery != searchQuery) return null;
    if (snapshot.confirmedOnly != confirmedOnly) return null;
    return snapshot;
  }

  @override
  void writeHomeAgendaCache(HomeAgendaCacheSnapshot snapshot) {
    homeAgendaCacheStreamValue.addValue(snapshot);
    homeAgendaEventsStreamValue.addValue(snapshot.events);
  }

  @override
  void clearHomeAgendaCache() {
    homeAgendaCacheStreamValue.addValue(null);
    homeAgendaEventsStreamValue.addValue(null);
  }

  @override
  Future<List<EventModel>> getAllEvents() async => const [];

  @override
  Future<EventModel?> getEventBySlug(String slug) async => null;

  @override
  Future<List<EventModel>> getEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async =>
      const [];

  @override
  Future<void> refreshEventsByDate(
    DateTime date, {
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    final events = await getEventsByDate(
      date,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    eventsByDateStreamValue.addValue(events);
  }

  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    lastOriginLat = originLat;
    lastOriginLng = originLng;
    return const PagedEventsResult(events: [], hasMore: false);
  }

  @override
  Future<void> refreshEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    final pageResult = await getEventsPage(
      page: page,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    pagedEventsStreamValue.addValue(pageResult);
  }

  @override
  Future<void> loadEventsPage({
    int pageSize = 25,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    _currentPagedEventsPage = 1;
    await refreshEventsPage(
      page: 1,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final result = pagedEventsStreamValue.value;
    hasMorePagedEventsStreamValue.addValue(result?.hasMore ?? false);
  }

  @override
  Future<void> loadNextEventsPage({
    int pageSize = 25,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    if (!hasMorePagedEventsStreamValue.value) {
      return;
    }
    final nextPage = _currentPagedEventsPage + 1;
    _currentPagedEventsPage = nextPage;
    await refreshEventsPage(
      page: nextPage,
      pageSize: pageSize,
      showPastOnly: showPastOnly,
      searchQuery: searchQuery,
      categories: categories,
      tags: tags,
      taxonomy: taxonomy,
      confirmedOnly: confirmedOnly,
      originLat: originLat,
      originLng: originLng,
      maxDistanceMeters: maxDistanceMeters,
    );
    final result = pagedEventsStreamValue.value;
    hasMorePagedEventsStreamValue.addValue(result?.hasMore ?? false);
  }

  @override
  void resetPagedEventsState() {
    _currentPagedEventsPage = 0;
    pagedEventsStreamValue.addValue(null);
    hasMorePagedEventsStreamValue.addValue(true);
    isPagedEventsPageLoadingStreamValue.addValue(false);
    pagedEventsErrorStreamValue.addValue(null);
  }

  @override
  Future<ScheduleSummaryModel> getScheduleSummary() async {
    throw UnimplementedError();
  }

  @override
  Future<List<VenueEventResume>> getEventResumesByDate(DateTime date) async =>
      const [];

  @override
  Future<List<VenueEventResume>> fetchUpcomingEvents() async => const [];

  @override
  Stream<EventDeltaModel> watchEventsStream({
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) {
    return const Stream<EventDeltaModel>.empty();
  }

  @override
  Stream<void> watchEventsSignal({
    required void Function(EventDeltaModel delta) onDelta,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
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

class _FailingScheduleRepository extends _FakeScheduleRepository {
  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    throw Exception('forced first-page failure');
  }
}

class _FailingOnceScheduleRepository extends _FakeScheduleRepository {
  bool _failed = false;

  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    lastOriginLat = originLat;
    lastOriginLng = originLng;

    if (!_failed) {
      _failed = true;
      throw Exception('forced transient first-page failure');
    }

    return const PagedEventsResult(events: [], hasMore: false);
  }
}

class _AlwaysFailingScheduleRepository extends _FakeScheduleRepository {
  @override
  Future<PagedEventsResult> getEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String searchQuery = '',
    List<String>? categories,
    List<String>? tags,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) async {
    getEventsPageCallCount += 1;
    throw Exception('forced persistent first-page failure');
  }
}

class _PayloadScheduleBackend implements ScheduleBackendContract {
  @override
  Future<EventSummaryDTO> fetchSummary() async =>
      EventSummaryDTO(items: const []);

  @override
  Future<List<EventDTO>> fetchEvents() async => [
        _eventDto(),
      ];

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
  Future<EventSummaryDTO> fetchSummary() async =>
      EventSummaryDTO(items: const []);

  @override
  Future<List<EventDTO>> fetchEvents() async => [_pageOneEvent()];

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

class _FailingOnceThenDataBackend implements ScheduleBackendContract {
  int fetchEventsPageCallCount = 0;

  @override
  Future<EventSummaryDTO> fetchSummary() async =>
      EventSummaryDTO(items: const []);

  @override
  Future<List<EventDTO>> fetchEvents() async => [_eventDto()];

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

class _FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  Future<List<InviteModel>> fetchInvites(
          {int page = 1, int pageSize = 20}) async =>
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
  Future<InviteAcceptResult> acceptInvite(String inviteId) async =>
      buildInviteAcceptResult(
        inviteId: inviteId,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteAcceptResult> acceptInviteByCode(String code) async =>
      buildInviteAcceptResult(
        inviteId: 'mock-$code',
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async =>
      buildInviteDeclineResult(
        inviteId: inviteId,
        status: 'declined',
        groupHasOtherPending: false,
      );
  @override
  Future<List<InviteContactMatch>> importContacts(
          List<ContactModel> contacts) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async =>
      buildInviteShareCodeResult(
        code: 'CODE123',
        eventId: eventId,
        occurrenceId: occurrenceId,
      );

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
      String eventSlug) async {
    return const [];
  }

  @override
  Future<void> sendInvites(
    String eventSlug,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  bool throwOnRefreshConfirmedIds = false;

  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<void> confirmEventAttendance(String eventId) async {}

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  bool isEventConfirmed(String eventId) => false;

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {}

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
  Future<void> setLastKnownAddress(String? address) async {
    lastKnownAddressStreamValue.addValue(address);
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
    Duration minInterval = const Duration(seconds: 30),
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
