import 'dart:developer' as developer;
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/presentation/shared/location_permission/screens/location_permission_screen/location_permission_screen.dart';
import 'package:belluga_now/presentation/shared/widgets/button_loading.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/map_screen.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/widgets/shared/marker_core.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/immersive_event_detail_screen.dart';
import 'package:belluga_now/presentation/tenant_public/widgets/carousel_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'support/fake_schedule_repository.dart';
import 'support/integration_test_bootstrap.dart';

void main() {
  developer.postEvent(
    'seed_vm_golden_stream',
    const <String, Object>{},
    stream: 'integration_test.VmServiceProxyGoldenFileComparator',
  );
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();
  final originalGeolocator = GeolocatorPlatform.instance;
  const userTokenKey = 'user_token';
  const userIdKey = 'user_id';
  const deviceIdKey = 'device_id';

  setUpAll(() {
    GeolocatorPlatform.instance = _TestGeolocatorPlatform();
  });

  tearDownAll(() {
    GeolocatorPlatform.instance = originalGeolocator;
  });

  Future<void> _waitForFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 30),
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

  Future<bool> _waitForMaybeFinder(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
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
    final permissionScreen = find.byType(LocationPermissionScreen);
    if (await _waitForMaybeFinder(tester, permissionScreen)) {
      final continueButton = find.text('Continuar sem localização');
      if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton.first);
      } else {
        final allowButton = find.byType(ButtonLoading);
        await tester.tap(allowButton.first);
      }
      await _pumpFor(tester, const Duration(seconds: 1));
    }
  }

  Finder _mainFabFinder() {
    return find.byWidgetPredicate(
      (widget) =>
          widget is FloatingActionButton && widget.heroTag == 'map-fab-main',
    );
  }

  Finder _mapExpandedActionFinder() {
    return find.byWidgetPredicate((widget) {
      if (widget is! FloatingActionButton) {
        return false;
      }
      final heroTag = widget.heroTag?.toString() ?? '';
      return heroTag.startsWith('expanded-');
    });
  }

  bool _containsMyLocationIcon(Element root) {
    var found = false;

    void visit(Element element) {
      if (found) {
        return;
      }
      final widget = element.widget;
      if (widget is Icon && widget.icon == Icons.my_location) {
        found = true;
        return;
      }
      element.visitChildren(visit);
    }

    visit(root);
    return found;
  }

  Future<void> _clearAuthStorage() async {
    await AuthRepository.storage.delete(key: userTokenKey);
    await AuthRepository.storage.delete(key: userIdKey);
    await AuthRepository.storage.delete(key: deviceIdKey);
  }

  testWidgets(
    'Map event carousel, details sheet, filters, and marker border',
    (tester) async {
      await _clearAuthStorage();
      final getIt = GetIt.I;
      _unregisterIfRegistered<ApplicationContract>();
      _unregisterIfRegistered<AppDataRepository>();
      _unregisterIfRegistered<AuthRepositoryContract>();
      _unregisterIfRegistered<ScheduleRepositoryContract>();
      _unregisterIfRegistered<UserEventsRepositoryContract>();
      _unregisterIfRegistered<InvitesRepositoryContract>();
      _unregisterIfRegistered<UserLocationRepositoryContract>();

      getIt.registerSingleton<AppDataRepository>(
        AppDataRepository(
          backend: AppDataBackend(),
          localInfoSource: AppDataLocalInfoSource(),
        ),
      );
      getIt.registerSingleton<ScheduleRepositoryContract>(
        _FakeScheduleRepository(),
      );
      getIt.registerSingleton<UserEventsRepositoryContract>(
        _FakeUserEventsRepository(),
      );
      getIt.registerSingleton<InvitesRepositoryContract>(
        _FakeInvitesRepository(),
      );
      getIt.registerSingleton<UserLocationRepositoryContract>(
        _FakeUserLocationRepository(),
      );
      final app = Application();
      getIt.registerSingleton<ApplicationContract>(app);
      await app.init();
      final authRepository = GetIt.I.get<AuthRepositoryContract>();
      final now = DateTime.now().millisecondsSinceEpoch;
      final email = 'map-filter-$now@belluga.test';
      const password = 'SecurePass!123';

      await authRepository.signUpWithEmailPassword(
        authRepoString('Map Integration'),
        authRepoString(email),
        authRepoString(password),
      );
      if (authRepository.userToken.trim().isEmpty) {
        await authRepository.loginWithEmailPassword(
          authRepoString(email),
          authRepoString(password),
        );
      }
      expect(authRepository.userToken.trim(), isNotEmpty);

      await tester.pumpWidget(app);
      await _pumpFor(tester, const Duration(seconds: 2));
      await _dismissLocationGateIfNeeded(tester);
      await _dismissInviteOverlayIfNeeded(tester);
      await _waitForFinder(
        tester,
        find.text('Seus Favoritos', skipOffstage: false),
      );

      await tester.tap(find.widgetWithText(NavigationDestination, 'Mapa'));
      await _pumpFor(tester, const Duration(seconds: 1));
      await _dismissLocationGateIfNeeded(tester);
      await _waitForFinder(tester, find.byType(MapScreen));
      await _waitForFinder(tester, _mainFabFinder());

      final expandedActions = _mapExpandedActionFinder();
      var hasExpandedActions = await _waitForMaybeFinder(
        tester,
        expandedActions,
        timeout: const Duration(seconds: 3),
      );
      if (!hasExpandedActions) {
        await tester.tap(_mainFabFinder());
        await _pumpFor(tester, const Duration(seconds: 1));
        hasExpandedActions = await _waitForMaybeFinder(
          tester,
          expandedActions,
          timeout: const Duration(seconds: 3),
        );
      }
      var hasCarousel = false;
      if (hasExpandedActions) {
        final expandedWidgets =
            expandedActions.evaluate().toList(growable: false);
        final filterCandidates = expandedWidgets
            .where((element) => !_containsMyLocationIcon(element))
            .toList(growable: false);

        if (filterCandidates.isNotEmpty) {
          final categoryFilter = find.byWidget(
            filterCandidates.last.widget,
            skipOffstage: false,
          );
          await tester.tap(categoryFilter.first);
          await _pumpFor(tester, const Duration(seconds: 1));
          hasCarousel = await _waitForMaybeFinder(
            tester,
            find.byType(CarouselCard),
            timeout: const Duration(seconds: 10),
          );
          if (hasCarousel) {
            expect(find.byType(CarouselCard), findsWidgets);
            final detailsButton = find.widgetWithText(FilledButton, 'Detalhes');
            if (await _waitForMaybeFinder(tester, detailsButton)) {
              await tester.tap(detailsButton.first);
              await _pumpFor(tester, const Duration(seconds: 1));
              await _waitForFinder(
                tester,
                find.byType(ImmersiveEventDetailScreen),
              );

              final barrier = find.byType(ModalBarrier);
              if (barrier.evaluate().isNotEmpty) {
                await tester.tap(barrier.first);
                await _pumpFor(tester, const Duration(seconds: 1));
              }
            }
          }
        }
      }

      final markerCore = find.byType(MarkerCore);
      final hasMarker = await _waitForMaybeFinder(
        tester,
        markerCore,
        timeout: const Duration(seconds: 10),
      );
      if (hasMarker) {
        final markerContainer = find.descendant(
          of: markerCore.first,
          matching: find.byType(Container),
        );
        final containerWidget = tester.widget<Container>(markerContainer.first);
        final decoration = containerWidget.decoration as BoxDecoration;
        expect(decoration.border, isNull);
      }

      await tester.tap(_mainFabFinder());
      await _pumpFor(tester, const Duration(seconds: 1));
      if (hasCarousel) {
        expect(find.byType(CarouselCard), findsNothing);
      }

      await tester.tap(_mainFabFinder());
      await _pumpFor(tester, const Duration(seconds: 1));
      expect(find.byIcon(Icons.tune), findsOneWidget);
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
    speedAccuracy: 0.0,
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

  @override
  Stream<ServiceStatus> getServiceStatusStream() =>
      Stream.value(ServiceStatus.enabled);

  @override
  Stream<Position> getPositionStream({
    LocationSettings? locationSettings,
  }) {
    return Stream<Position>.value(_position);
  }

  @override
  Future<LocationAccuracyStatus> requestTemporaryFullAccuracy({
    required String purposeKey,
  }) async =>
      LocationAccuracyStatus.precise;

  @override
  Future<LocationAccuracyStatus> getLocationAccuracy() async =>
      LocationAccuracyStatus.precise;

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

void _unregisterIfRegistered<T extends Object>() {
  if (GetIt.I.isRegistered<T>()) {
    GetIt.I.unregister<T>();
  }
}

class _FakeScheduleRepository extends IntegrationTestScheduleRepositoryFake {}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
          defaultValue: const {});

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<void> unconfirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {}

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
          UserEventsRepositoryContractPrimString eventId) =>
      userEventsRepoBool(false, defaultValue: false, isRequired: true);
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
    InviteContacts contacts,
  ) async =>
      const [];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async =>
      buildInviteShareCodeResult(
        code: 'test-share-code',
        eventId: eventId.value,
        occurrenceId: occurrenceId?.value,
      );

  @override
  Future<void> sendInvites(InvitesRepositoryContractPrimString eventSlug,
      InviteRecipients recipients,
      {InvitesRepositoryContractPrimString? occurrenceId,
      InvitesRepositoryContractPrimString? message}) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
          InvitesRepositoryContractPrimString eventSlug) async =>
      const [];
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  @override
  final userLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownCapturedAtStreamValue = StreamValue<DateTime?>();

  @override
  final lastKnownAccuracyStreamValue = StreamValue<double?>();

  @override
  final lastKnownAddressStreamValue = StreamValue<String?>();

  @override
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
          defaultValue: LocationResolutionPhase.unknown);

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(Object? address) async {}

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({
    Object? minInterval,
  }) async =>
      false;

  @override
  Future<String?> resolveUserLocation() async => null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      false;

  @override
  Future<void> stopTracking() async {}
}
