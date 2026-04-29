import 'dart:developer' as developer;
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

import 'package:belluga_now/application/application.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/domain/auth/auth_phone_otp_challenge.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_challenge_id_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_delivery_channel_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
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
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/app_data_backend_stub.dart';
import 'package:belluga_now/infrastructure/platform/app_data_local_info_source/app_data_local_info_source.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/auth_repository.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/auth_login_screen.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/auth_login_controller.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';
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

  const userTokenKey = 'user_token';
  const userIdKey = 'user_id';
  const deviceIdKey = 'device_id';

  Future<void> _clearAuthStorage() async {
    await AuthRepository.storage.delete(key: userTokenKey);
    await AuthRepository.storage.delete(key: userIdKey);
    await AuthRepository.storage.delete(key: deviceIdKey);
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

  Future<void> _waitForPath(
    ApplicationContract app,
    String path, {
    Duration timeout = const Duration(seconds: 20),
    Duration step = const Duration(milliseconds: 300),
    String Function()? diagnostics,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(step);
      if (app.appRouter.currentPath == path) {
        return;
      }
    }
    final extra = diagnostics != null ? ' ${diagnostics()}' : '';
    throw TestFailure('Timed out waiting for path $path.$extra');
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

  testWidgets('Login navigates back to intended route', (tester) async {
    await _clearAuthStorage();
    final getIt = GetIt.I;
    _unregisterIfRegistered<ApplicationContract>();
    _unregisterIfRegistered<AppDataRepository>();
    _unregisterIfRegistered<ScheduleRepositoryContract>();
    _unregisterIfRegistered<UserEventsRepositoryContract>();
    _unregisterIfRegistered<InvitesRepositoryContract>();
    _unregisterIfRegistered<UserLocationRepositoryContract>();
    _unregisterIfRegistered<AuthRepositoryContract>();

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
    getIt.registerSingleton<AuthRepositoryContract>(
      _FakePhoneOtpAuthRepository(),
    );
    final app = Application();
    getIt.registerSingleton<ApplicationContract>(app);
    await app.init();

    _unregisterIfRegistered<AuthLoginControllerContract>();
    getIt.registerSingleton<AuthLoginControllerContract>(
      AuthLoginController(),
    );

    await tester.pumpWidget(app);
    await _pumpFor(tester, const Duration(seconds: 2));

    app.appRouter.pushPath('/auth/login?redirect=%2Fagenda');
    await _pumpFor(tester, const Duration(seconds: 1));
    await _waitForPath(
      app,
      '/auth/login',
      diagnostics: () {
        final path = app.appRouter.currentPath;
        final top = app.appRouter.topRoute.name;
        return '(currentPath=$path, topRoute=$top)';
      },
    );

    await _waitForFinder(
      tester,
      find.byType(AuthLoginScreen, skipOffstage: false),
    );

    final phoneField = find.byKey(
      WidgetKeys.auth.loginPhoneField,
      skipOffstage: false,
    );
    await _waitForFinder(tester, phoneField);
    expect(find.byKey(WidgetKeys.auth.loginPasswordField), findsNothing);

    await tester.ensureVisible(phoneField.first);
    await _pumpFor(tester, const Duration(milliseconds: 300));
    await tester.enterText(phoneField, '+55 27 99999-0000');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await _pumpFor(tester, const Duration(milliseconds: 500));

    final loginButton = find.byKey(
      WidgetKeys.auth.loginButton,
      skipOffstage: false,
    );
    await _waitForFinder(tester, loginButton);
    final elevatedLoginButton = find.descendant(
      of: loginButton,
      matching: find.byType(ElevatedButton),
      skipOffstage: false,
    );
    await _waitForFinder(tester, elevatedLoginButton);
    await tester.ensureVisible(elevatedLoginButton.first);
    await tester.tap(elevatedLoginButton.first, warnIfMissed: false);
    await _pumpFor(tester, const Duration(seconds: 1));

    final otpCodeField = find.byKey(
      WidgetKeys.auth.loginOtpCodeField,
      skipOffstage: false,
    );
    await _waitForFinder(tester, otpCodeField);
    await tester.ensureVisible(otpCodeField.first);
    await _pumpFor(tester, const Duration(milliseconds: 300));
    await tester.enterText(otpCodeField, '123456');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await _pumpFor(tester, const Duration(milliseconds: 500));

    await _waitForFinder(tester, elevatedLoginButton);
    await tester.ensureVisible(elevatedLoginButton.first);
    await tester.tap(elevatedLoginButton.first, warnIfMissed: false);
    await _pumpFor(tester, const Duration(seconds: 2));

    await _dismissLocationGateIfNeeded(tester);
    await _dismissInviteOverlayIfNeeded(tester);

    await _waitForPath(
      app,
      '/agenda',
      diagnostics: () {
        final path = app.appRouter.currentPath;
        final top = app.appRouter.topRoute.name;
        return '(currentPath=$path, topRoute=$top)';
      },
    );
  });
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
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  @override
  Future<LocationPermission> checkPermission() async {
    return LocationPermission.always;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return LocationPermission.always;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    return _position;
  }
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

class _FakePhoneOtpAuthRepository extends AuthRepositoryContract<UserBelluga> {
  bool _authorized = false;
  String _token = '';
  String? _userId;

  @override
  Object get backend => Object();

  @override
  String get userToken => _token;

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {
    _token = token?.value ?? '';
  }

  @override
  Future<String> getDeviceId() async => 'integration-device-id';

  @override
  Future<String?> getUserId() async => _userId;

  @override
  bool get isUserLoggedIn => userStreamValue.value != null;

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
  ) async {
    throw UnimplementedError('Tenant public login uses phone OTP.');
  }

  @override
  Future<AuthPhoneOtpChallenge> requestPhoneOtpChallenge(
    AuthRepositoryContractParamString phone, {
    AuthRepositoryContractParamString? deliveryChannel,
  }) async {
    return AuthPhoneOtpChallenge(
      challengeIdValue: AuthPhoneOtpChallengeIdValue()
        ..parse('integration-otp-challenge'),
      phoneValue: AuthPhoneOtpPhoneValue()..parse(phone.value),
      deliveryChannelValue: AuthPhoneOtpDeliveryChannelValue()
        ..parse(deliveryChannel?.value ?? 'whatsapp'),
      expiresAtValue: DomainOptionalDateTimeValue()
        ..set(DateTime.utc(2026, 4, 28, 23)),
      resendAvailableAtValue: DomainOptionalDateTimeValue()
        ..set(DateTime.utc(2026, 4, 28, 22, 45)),
    );
  }

  @override
  Future<void> verifyPhoneOtpChallenge({
    required AuthRepositoryContractParamString challengeId,
    required AuthRepositoryContractParamString phone,
    required AuthRepositoryContractParamString code,
  }) async {
    if (challengeId.value != 'integration-otp-challenge' ||
        code.value != '123456') {
      throw StateError('Invalid fake OTP challenge.');
    }
    _authorized = true;
    _token = 'integration-otp-token';
    _userId = '507f1f77bcf86cd799439011';
    userStreamValue.addValue(
      UserBelluga(
        uuidValue: MongoIDValue()..parse(_userId!),
        profile: UserProfileContract(),
      ),
    );
  }

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {
    throw UnimplementedError('Signup is not part of this login redirect test.');
  }

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {
    _authorized = false;
    _token = '';
    _userId = null;
    userStreamValue.addValue(null);
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
