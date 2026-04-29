import 'package:belluga_now/testing/domain_factories.dart';
import 'dart:developer' as developer;
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
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
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/admin_mode_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/schedule_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/tenant/value_objects/app_domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/domain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/icon_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_color_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/main_logo_url_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/subdomain_value.dart';
import 'package:belluga_now/domain/tenant/value_objects/tenant_name_value.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/auth_login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

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

  setUpAll(() {
    GeolocatorPlatform.instance = _TestGeolocatorPlatform();
  });

  tearDownAll(() {
    GeolocatorPlatform.instance = originalGeolocator;
  });

  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets(
    'anonymous confirm -> signup -> confirm keeps single event route and preserves confirmed state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 960));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      const eventSlug = 'evento-regressao-stack';
      final event = _buildEvent(slug: eventSlug);
      final scheduleRepository = _FakeScheduleRepository(event: event);
      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      final authRepository = _MutableFakeAuthRepository();

      _unregisterIfRegistered<ApplicationContract>();
      _unregisterIfRegistered<AppDataRepositoryContract>();
      _unregisterIfRegistered<ScheduleRepositoryContract>();
      _unregisterIfRegistered<UserEventsRepositoryContract>();
      _unregisterIfRegistered<InvitesRepositoryContract>();
      _unregisterIfRegistered<UserLocationRepositoryContract>();
      _unregisterIfRegistered<AuthRepositoryContract>();
      _unregisterIfRegistered<TenantRepositoryContract>();
      _unregisterIfRegistered<LandlordAuthRepositoryContract>();
      _unregisterIfRegistered<AdminModeRepositoryContract>();

      final getIt = GetIt.I;
      getIt.registerSingleton<AppDataRepositoryContract>(
        _FakeAppDataRepository(
          _buildAppData(mainDomain: 'guarappari.belluga.space'),
        ),
      );
      getIt.registerSingleton<ScheduleRepositoryContract>(scheduleRepository);
      getIt.registerSingleton<UserEventsRepositoryContract>(
          userEventsRepository);
      getIt.registerSingleton<InvitesRepositoryContract>(invitesRepository);
      getIt.registerSingleton<UserLocationRepositoryContract>(
        _FakeUserLocationRepository(),
      );
      getIt.registerSingleton<AuthRepositoryContract>(authRepository);
      getIt.registerSingleton<TenantRepositoryContract>(
        _FakeTenantRepository(),
      );
      getIt.registerSingleton<LandlordAuthRepositoryContract>(
        _FakeLandlordAuthRepository(),
      );
      getIt.registerSingleton<AdminModeRepositoryContract>(
        _FakeAdminModeRepository(),
      );

      final app = Application();
      getIt.registerSingleton<ApplicationContract>(app);
      await app.init();

      await tester.pumpWidget(app);
      await _pumpFor(tester, const Duration(seconds: 2));
      await _waitForRoute(app, TenantHomeRoute.name);

      app.appRouter.replaceAll([EventSearchRoute()]);
      await _pumpFor(tester, const Duration(seconds: 1));

      app.appRouter.push(ImmersiveEventDetailRoute(eventSlug: eventSlug));
      await _waitForFinder(tester, find.textContaining('Confirmar Presença'));

      await tester.tap(find.textContaining('Confirmar Presença').first);
      await _pumpFor(tester, const Duration(seconds: 1));

      await _waitForFinder(
        tester,
        find.byType(AuthLoginScreen, skipOffstage: false),
      );

      final openSignupButton = find.widgetWithText(TextButton, 'Criar conta');
      await _waitForFinder(tester, openSignupButton.first);
      await tester.ensureVisible(openSignupButton.first);
      await tester.tap(openSignupButton.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(seconds: 1));

      final bottomSheet = find.byType(BottomSheet);
      await _waitForFinder(tester, bottomSheet);

      final nameField = find.descendant(
        of: bottomSheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'Nome',
        ),
      );
      final emailField = find.descendant(
        of: bottomSheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'E-mail',
        ),
      );
      final passwordField = find.descendant(
        of: bottomSheet,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is TextField && widget.decoration?.labelText == 'Senha',
        ),
      );

      await _waitForFinder(tester, nameField);
      await _waitForFinder(tester, emailField);
      await _waitForFinder(tester, passwordField);

      final now = DateTime.now().millisecondsSinceEpoch;
      await tester.enterText(nameField, 'Stack Regression');
      await tester.enterText(emailField, 'stack-regression-$now@belluga.test');
      await tester.enterText(passwordField, 'SecurePass!123');
      await tester.pump();

      final submitButton = find.widgetWithText(FilledButton, 'Criar conta');
      await _waitForFinder(tester, submitButton);
      await tester.ensureVisible(submitButton.first);
      await tester.tap(submitButton.first, warnIfMissed: false);
      await _pumpFor(tester, const Duration(seconds: 2));

      await _dismissLocationGateIfNeeded(tester);
      await _dismissInviteOverlayIfNeeded(tester);

      await _waitForRoute(app, ImmersiveEventDetailRoute.name);
      await _waitForPath(app, '/agenda/evento/$eventSlug');

      await tester.tap(find.textContaining('Confirmar Presença').first);
      await _pumpFor(tester, const Duration(seconds: 1));

      await _waitForFinder(tester, find.text('BORA? Agitar a galera!'));
      expect(userEventsRepository.confirmCalls, 1);
      expect(
        userEventsRepository
            .isOccurrenceConfirmed(
              userEventsRepoString(
                event.selectedOccurrenceId ?? '',
                defaultValue: '',
                isRequired: true,
              ),
            )
            .value,
        isTrue,
      );

      await app.appRouter.maybePop();
      await _pumpFor(tester, const Duration(milliseconds: 500));

      await _waitForRoute(app, EventSearchRoute.name);
      await _waitForPath(app, '/agenda');

      final exceptions = _takeAllExceptions(tester);
      expect(exceptions, isEmpty, reason: exceptions.join('\n---\n'));
    },
  );
}

void _unregisterIfRegistered<T extends Object>() {
  if (GetIt.I.isRegistered<T>()) {
    GetIt.I.unregister<T>();
  }
}

Future<void> _waitForFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 45),
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

Future<void> _waitForRoute(
  ApplicationContract app,
  String routeName, {
  Duration timeout = const Duration(seconds: 45),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(step);
    if (app.appRouter.topRoute.name == routeName) {
      return;
    }
  }
  throw TestFailure(
    'Timed out waiting for route $routeName '
    '(currentPath=${app.appRouter.currentPath}, top=${app.appRouter.topRoute.name}).',
  );
}

Future<void> _waitForPath(
  ApplicationContract app,
  String expectedPath, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 250),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(step);
    if (app.appRouter.currentPath == expectedPath) {
      return;
    }
  }
  throw TestFailure(
    'Timed out waiting for path $expectedPath '
    '(currentPath=${app.appRouter.currentPath}, top=${app.appRouter.topRoute.name}).',
  );
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<bool> _waitForMaybeFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
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

Future<void> _dismissInviteOverlayIfNeeded(WidgetTester tester) async {
  final closeButton = find.byTooltip('Fechar');
  if (await _waitForMaybeFinder(tester, closeButton)) {
    await tester.tap(closeButton.first);
    await _pumpFor(tester, const Duration(seconds: 1));
  }
}

Future<void> _dismissLocationGateIfNeeded(WidgetTester tester) async {
  final allowButton = find.text('Permitir localização');
  if (await _waitForMaybeFinder(tester, allowButton)) {
    await tester.tap(allowButton.first);
    await _pumpFor(tester, const Duration(seconds: 2));
  }

  final continueButton = find.text('Continuar sem localização ao vivo');
  if (await _waitForMaybeFinder(tester, continueButton)) {
    await tester.tap(continueButton.first);
    await _pumpFor(tester, const Duration(seconds: 1));
  }

  final notNowButton = find.text('Agora não');
  if (await _waitForMaybeFinder(tester, notNowButton)) {
    await tester.tap(notNowButton.first);
    await _pumpFor(tester, const Duration(seconds: 1));
  }
}

List<String> _takeAllExceptions(WidgetTester tester) {
  final messages = <String>[];
  while (true) {
    final error = tester.takeException();
    if (error == null) {
      break;
    }
    messages.add(error.toString());
  }
  return messages;
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
    speedAccuracy: 1.0,
  );

  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.whileInUse;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return LocationPermission.whileInUse;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    return _position;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return _position;
  }
}

AppData _buildAppData({
  required String mainDomain,
}) {
  final origin = _requireOriginUri(mainDomain);
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'profile_types': const [],
    'domains': [origin.host],
    'app_domains': const ['com.guarappari.app'],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#009688',
      'secondary_seed_color': '#3F51B5',
    },
    'main_color': '#009688',
    'main_domain': origin.toString(),
    'tenant_id': 'tenant-1',
    'telemetry': const {
      'trackers': [],
    },
    'telemetry_context': const {'location_freshness_minutes': 5},
    'push': const {
      'enabled': true,
      'types': ['event'],
      'throttles': {'max_per_hour': 20},
    },
  };

  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': origin.host,
    'href': origin.toString(),
    'port': origin.hasPort ? origin.port.toString() : null,
    'device': 'integration-test-device',
  };

  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

Uri _requireOriginUri(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw StateError('mainDomain cannot be empty.');
  }
  final hasScheme =
      trimmed.startsWith('http://') || trimmed.startsWith('https://');
  final candidate = hasScheme ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(candidate);
  if (uri == null || uri.host.trim().isEmpty) {
    throw StateError('Invalid origin: $raw');
  }
  return uri;
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;
  final StreamValue<ThemeMode?> _themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);
  final StreamValue<DistanceInMetersValue> _maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
          defaultValue:
              DistanceInMetersValue.fromRaw(1000, defaultValue: 1000));

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {
    if (GetIt.I.isRegistered<AppData>()) {
      GetIt.I.unregister<AppData>();
    }
    GetIt.I.registerSingleton<AppData>(_appData);
  }

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;

  @override
  ThemeMode get themeMode => _themeModeStreamValue.value ?? ThemeMode.system;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    _themeModeStreamValue.addValue(mode.value);
  }

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      _maxRadiusMetersStreamValue.value;

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    _maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeScheduleRepository extends IntegrationTestScheduleRepositoryFake {
  _FakeScheduleRepository({required EventModel event})
      : super(
          seededEvents: <EventModel>[event],
          slugResolver: ({
            required List<EventModel> seededEvents,
            required String slug,
          }) {
            for (final candidate in seededEvents) {
              if (candidate.slugValue.value == slug) {
                return candidate;
              }
            }
            return null;
          },
        );
}

class _FakeTenantRepository extends TenantRepositoryContract {
  @override
  AppData get appData => GetIt.I.get<AppData>();

  @override
  Future<Tenant> fetchTenant() async {
    return Tenant(
      name: TenantNameValue()..parse('Tenant Test'),
      subdomain: SubdomainValue()..parse('guarappari'),
      mainLogoUrl: MainLogoUrlValue()..parse('https://example.com/logo.png'),
      iconUrl: IconUrlValue()..parse('https://example.com/icon.png'),
      mainColor: MainColorValue()..parse('#009688'),
      domains: <DomainValue>[
        DomainValue()..parse(appData.mainDomainValue.value.toString()),
      ],
      appDomains: <AppDomainValue>[
        AppDomainValue()..parse('com.guarappari.app'),
      ],
    );
  }
}

class _FakeLandlordAuthRepository implements LandlordAuthRepositoryContract {
  @override
  bool get hasValidSession => false;

  @override
  String get token => '';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
    LandlordAuthRepositoryContractPrimString email,
    LandlordAuthRepositoryContractPrimString password,
  ) async {}

  @override
  Future<void> logout() async {}
}

class _FakeAdminModeRepository implements AdminModeRepositoryContract {
  @override
  final StreamValue<AdminMode> modeStreamValue = StreamValue<AdminMode>(
    defaultValue: AdminMode.user,
  );

  @override
  AdminMode get mode => modeStreamValue.value;

  @override
  bool get isLandlordMode => mode == AdminMode.landlord;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLandlordMode() async {
    modeStreamValue.addValue(AdminMode.landlord);
  }

  @override
  Future<void> setUserMode() async {
    modeStreamValue.addValue(AdminMode.user);
  }
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const <UserEventsRepositoryContractPrimString>{},
  );

  final Set<String> _confirmedIds = <String>{};
  int confirmCalls = 0;

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {
    confirmCalls += 1;
    _confirmedIds.add(occurrenceId.value);
    confirmedOccurrenceIdsStream.addValue(
      _confirmedIds
          .map(
            (value) => userEventsRepoString(
              value,
              defaultValue: '',
              isRequired: true,
            ),
          )
          .toSet(),
    );
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
    UserEventsRepositoryContractPrimString occurrenceId,
  ) =>
      userEventsRepoBool(
        _confirmedIds.contains(occurrenceId.value),
        defaultValue: false,
        isRequired: true,
      );

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {
    confirmedOccurrenceIdsStream.addValue(
      _confirmedIds
          .map(
            (value) => userEventsRepoString(
              value,
              defaultValue: '',
              isRequired: true,
            ),
          )
          .toSet(),
    );
  }

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {
    _confirmedIds.remove(occurrenceId.value);
    confirmedOccurrenceIdsStream.addValue(
      _confirmedIds
          .map(
            (value) => userEventsRepoString(
              value,
              defaultValue: '',
              isRequired: true,
            ),
          )
          .toSet(),
    );
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  Future<InviteAcceptResult> acceptInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    return buildInviteAcceptResult(
      inviteId: inviteId.value,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    return buildInviteAcceptResult(
      inviteId: 'mock-${code.value}',
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    return buildInviteShareCodeResult(
      code: 'CODE123',
      eventId: eventId.value,
      occurrenceId: occurrenceId?.value ?? 'occurrence-1',
    );
  }

  @override
  Future<InviteDeclineResult> declineInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    return buildInviteDeclineResult(
      inviteId: inviteId.value,
      status: 'declined',
      groupHasOtherPending: false,
    );
  }

  @override
  Future<List<InviteModel>> fetchInvites(
      {InvitesRepositoryContractPrimInt? page,
      InvitesRepositoryContractPrimInt? pageSize}) async {
    return const <InviteModel>[];
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    return buildInviteRuntimeSettings(
      tenantId: null,
      limits: {},
      cooldowns: {},
      overQuotaMessage: null,
    );
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
      InvitesRepositoryContractPrimString eventId) async {
    return const <SentInviteStatus>[];
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    return const <InviteContactMatch>[];
  }

  @override
  Future<void> sendInvites(
      InvitesRepositoryContractPrimString eventId, InviteRecipients recipients,
      {InvitesRepositoryContractPrimString? occurrenceId,
      InvitesRepositoryContractPrimString? message}) async {}
}

class _MutableFakeAuthRepository extends AuthRepositoryContract<UserContract> {
  bool _authorized = false;
  String _token = '';

  @override
  Object get backend => Object();

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> createNewPassword(AuthRepositoryContractParamString newPassword,
      AuthRepositoryContractParamString confirmPassword) {
    return Future<void>.value();
  }

  @override
  Future<String> getDeviceId() async => 'integration-device';

  @override
  Future<String?> getUserId() async => _authorized ? 'integration-user' : null;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthorized => _authorized;

  @override
  bool get isUserLoggedIn => _authorized;

  @override
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {
    _setAuthorized();
  }

  @override
  Future<void> logout() async {
    _authorized = false;
    _token = '';
    userStreamValue.addValue(null);
  }

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {
    _token = token?.value ?? '';
  }

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {
    _setAuthorized(name: name.value, email: email.value);
  }

  @override
  Future<void> updateUser(UserCustomData data) async {}

  @override
  String get userToken => _token;

  void _setAuthorized({String? name, String? email}) {
    _authorized = true;
    _token = 'integration-token';
    userStreamValue.addValue(
      _FakeUser(
        name: name ?? 'Integration User',
        email: email ?? 'integration@belluga.test',
      ),
    );
  }
}

class _FakeUser extends UserContract {
  _FakeUser({required String name, required String email})
      : super(
          uuidValue: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
          profile: UserProfileContract(
            nameValue: null,
            emailValue: null,
          ),
        );
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>();

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>();

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>();

  @override
  final StreamValue<String?> lastKnownAddressStreamValue =
      StreamValue<String?>();

  @override
  @override
  final StreamValue<LocationResolutionPhase>
      locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(Object? address) async {
    lastKnownAddressStreamValue.addValue(address as dynamic);
  }

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

EventModel _buildEvent({required String slug}) {
  return eventModelFromRaw(
    id: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
    slugValue: SlugValue()..parse(slug),
    type: EventTypeModel(
      id: EventTypeIdValue()..parse('show'),
      name: TitleValue()..parse('Show tipo'),
      slug: SlugValue()..parse('show'),
      description: DescriptionValue()..parse('Descricao longa do tipo.'),
      icon: SlugValue()..parse('music'),
      color: ColorValue(defaultValue: Colors.blue)..parse('#3366FF'),
    ),
    title: TitleValue()..parse('Evento de Regressao'),
    content: HTMLContentValue()..parse('Descricao longa do evento para teste.'),
    location: DescriptionValue()..parse('Local de teste'),
    venue: null,
    thumb: ThumbModel(
      thumbUri: ThumbUriValue(
        defaultValue: Uri.parse('https://example.com/event.png'),
      )..parse('https://example.com/event.png'),
      thumbType: ThumbTypeValue(defaultValue: ThumbTypes.image)
        ..parse(ThumbTypes.image.name),
    ),
    dateTimeStart: DateTimeValue(isRequired: true)
      ..parse(DateTime(2026, 3, 15, 20).toIso8601String()),
    dateTimeEnd: null,
    occurrences: [
      EventOccurrenceOption(
        occurrenceIdValue: EventLinkedAccountProfileTextValue(
          '507f1f77bcf86cd799439012',
        ),
        occurrenceSlugValue: EventLinkedAccountProfileTextValue(
          'evento-regressao-stack-2026-03-15',
        ),
        dateTimeStartValue: DateTimeValue(isRequired: true)
          ..parse(DateTime(2026, 3, 15, 20).toIso8601String()),
        dateTimeEndValue: DomainOptionalDateTimeValue(),
        isSelectedValue: EventOccurrenceFlagValue()..parse('true'),
        hasLocationOverrideValue: EventOccurrenceFlagValue()..parse('false'),
        programmingCountValue: EventProgrammingCountValue()..parse('0'),
      ),
    ],
    artists: const [],
    coordinate: null,
    tags: const <String>['show'],
    isConfirmedValue: EventIsConfirmedValue()..parse('false'),
    confirmedAt: null,
    receivedInvites: null,
    sentInvites: null,
    friendsGoing: null,
    totalConfirmedValue: EventTotalConfirmedValue()..parse('0'),
  );
}
