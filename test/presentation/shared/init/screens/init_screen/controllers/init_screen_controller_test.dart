import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/startup/app_startup_navigation_plan.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/deferred_link_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/presentation/shared/init/screens/init_screen/controllers/init_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

void main() {
  test('tenant without pending invites resolves tenant home stack', () async {
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: false),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
    );

    await controller.initialize();

    expect(controller.initialRoute, isA<TenantHomeRoute>());
    expect(
      controller.initialRouteStack.map((route) => route.routeName).toList(),
      [TenantHomeRoute.name],
    );
    expect(controller.startupNavigationPlan, isA<AppStartupNavigationPlan>());
    expect(controller.startupNavigationPlan.hasOverride, isFalse);
  });

  test('tenant with pending invites stacks invite flow on top of home',
      () async {
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: true),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
    );

    await controller.initialize();

    expect(controller.initialRoute, isA<InviteFlowRoute>());
    expect(
      controller.initialRouteStack.map((route) => route.routeName).toList(),
      [
        TenantHomeRoute.name,
        InviteFlowRoute.name,
      ],
    );
    expect(controller.startupNavigationPlan.hasOverride, isTrue);
  });

  test('landlord ignores tenant invite flow and resolves landlord home',
      () async {
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: true),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.landlord),
      ),
    );

    await controller.initialize();

    expect(controller.initialRoute, isA<LandlordHomeRoute>());
    expect(
      controller.initialRouteStack.map((route) => route.routeName).toList(),
      [LandlordHomeRoute.name],
    );
    expect(controller.startupNavigationPlan.hasOverride, isFalse);
  });

  test('initialize bootstraps auth before loading invites', () async {
    final authRepository = _FakeAuthRepository();
    final invitesRepository = _FakeInvitesRepository(hasPendingInvites: false);
    final controller = InitScreenController(
      authRepository: authRepository,
      invitesRepository: invitesRepository,
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
    );

    await controller.initialize();

    expect(authRepository.initCallCount, 1);
    expect(invitesRepository.initCallCount, 1);
  });

  test('captured deferred share code overrides first route path to invite',
      () async {
    final telemetry = _FakeTelemetryRepository();
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: false),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
      deferredLinkRepository: _FakeDeferredLinkRepository(
        DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.captured,
          codeValue: DeferredLinkCaptureCodeValue(defaultValue: 'ABCD1234'),
          targetPathValue: DeferredLinkTargetPathValue(
              defaultValue: '/invite?code=ABCD1234'),
          storeChannelValue:
              DeferredLinkStoreChannelValue(defaultValue: 'play'),
        ),
      ),
      telemetryRepository: telemetry,
    );

    await controller.initialize();

    expect(controller.initialRoutePath, '/invite?code=ABCD1234');
    expect(controller.startupNavigationPlan.hasOverride, isTrue);
    expect(telemetry.loggedEvents, hasLength(1));
    expect(
      telemetry.loggedEvents.single.eventName,
      'app_deferred_deep_link_captured',
    );
    expect(telemetry.loggedEvents.single.properties?['store_channel'], 'play');
    expect(
      telemetry.loggedEvents.single.properties?['target_path'],
      '/invite?code=ABCD1234',
    );
  });

  test('captured deferred target path overrides first route path', () async {
    final telemetry = _FakeTelemetryRepository();
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: false),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
      deferredLinkRepository: _FakeDeferredLinkRepository(
        DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.captured,
          targetPathValue: DeferredLinkTargetPathValue(
            defaultValue: '/agenda/evento/forro?occurrence=occ-1',
          ),
          storeChannelValue:
              DeferredLinkStoreChannelValue(defaultValue: 'play'),
        ),
      ),
      telemetryRepository: telemetry,
    );

    await controller.initialize();

    expect(
      controller.initialRoutePath,
      '/agenda/evento/forro?occurrence=occ-1',
    );
    expect(controller.startupNavigationPlan.hasOverride, isTrue);
    expect(
      telemetry.loggedEvents.single.properties?['target_path'],
      '/agenda/evento/forro?occurrence=occ-1',
    );
    expect(
        telemetry.loggedEvents.single.properties?.containsKey('code'), isFalse);
  });

  test('deferred capture telemetry includes fallback store_channel', () async {
    final telemetry = _FakeTelemetryRepository();
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: false),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
      deferredLinkRepository: _FakeDeferredLinkRepository(
        DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.captured,
          codeValue: DeferredLinkCaptureCodeValue(defaultValue: 'ABCD1234'),
          targetPathValue: DeferredLinkTargetPathValue(
              defaultValue: '/invite?code=ABCD1234'),
        ),
      ),
      telemetryRepository: telemetry,
    );

    await controller.initialize();

    expect(controller.initialRoutePath, '/invite?code=ABCD1234');
    expect(
      telemetry.loggedEvents.single.eventName,
      'app_deferred_deep_link_captured',
    );
    expect(
        telemetry.loggedEvents.single.properties?['store_channel'], 'unknown');
  });

  test('deferred failure telemetry includes fallback store_channel', () async {
    final telemetry = _FakeTelemetryRepository();
    final controller = InitScreenController(
      invitesRepository: _FakeInvitesRepository(hasPendingInvites: false),
      appDataRepository: _FakeAppDataRepository(
        _buildAppData(environmentType: EnvironmentType.tenant),
      ),
      deferredLinkRepository: _FakeDeferredLinkRepository(
        DeferredLinkCaptureResult(
          status: DeferredLinkCaptureStatus.notCaptured,
          failureReasonValue: DeferredLinkFailureReasonValue(
              defaultValue: 'resolver_not_captured'),
        ),
      ),
      telemetryRepository: telemetry,
    );

    await controller.initialize();

    expect(controller.initialRoutePath, isNull);
    expect(
      telemetry.loggedEvents.single.eventName,
      'app_deferred_deep_link_capture_failed',
    );
    expect(
        telemetry.loggedEvents.single.properties?['store_channel'], 'unknown');
  });
}

class _LoggedTelemetryEvent {
  const _LoggedTelemetryEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({required bool hasPendingInvites})
      : _hasPendingInvites = hasPendingInvites;

  @override
  InvitesRepositoryContractPrimBool get hasPendingInvites =>
      InvitesRepositoryContractPrimBool.fromRaw(
        _hasPendingInvites,
        defaultValue: false,
        isRequired: true,
      );
  final bool _hasPendingInvites;
  int initCallCount = 0;

  @override
  Future<void> init() async {
    initCallCount += 1;
    pendingInvitesStreamValue.addValue(
      _hasPendingInvites ? [_buildInvite()] : const [],
    );
  }

  @override
  Future<List<InviteModel>> fetchInvites(
      {InvitesRepositoryContractPrimInt? page,
      InvitesRepositoryContractPrimInt? pageSize}) async {
    return _hasPendingInvites ? [_buildInvite()] : const [];
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
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async {
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
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async {
    return buildInviteDeclineResult(
      inviteId: inviteId.value,
      status: 'declined',
      groupHasOtherPending: false,
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
      occurrenceId: occurrenceId?.value,
    );
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    InvitesRepositoryContractPrimString eventId,
  ) async {
    return const [];
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    return const [];
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}
}

class _FakeAuthRepository extends AuthRepositoryContract<UserBelluga> {
  int initCallCount = 0;

  @override
  Object get backend => throw UnimplementedError();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  @override
  Future<void> init() async {
    initCallCount += 1;
  }

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
  Future<void> logout() async {}

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

class _FakeDeferredLinkRepository implements DeferredLinkRepositoryContract {
  const _FakeDeferredLinkRepository(this.result);

  final DeferredLinkCaptureResult result;

  @override
  Future<DeferredLinkCaptureResult> captureFirstOpenInviteCode() async =>
      result;
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  final List<_LoggedTelemetryEvent> loggedEvents = <_LoggedTelemetryEvent>[];

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async =>
      telemetryRepoBool(true);

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async =>
      telemetryRepoBool(true);

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    loggedEvents.add(
      _LoggedTelemetryEvent(
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async =>
      telemetryRepoBool(true);

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async =>
      null;
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this.appData);

  @override
  final AppData appData;

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue.fromRaw(1000, defaultValue: 1000),
      );

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      DistanceInMetersValue.fromRaw(1000, defaultValue: 1000);

  @override
  bool get hasPersistedMaxRadiusPreference => false;

  @override
  ThemeMode get themeMode => ThemeMode.light;

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue =>
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  Future<void> init() async {}

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {}

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}
}

InviteModel _buildInvite() {
  return buildInviteModelFromPrimitives(
    id: 'invite-1',
    eventId: 'event-1',
    eventName: 'Evento',
    eventDateTime: DateTime(2026, 3, 15, 20),
    eventImageUrl: 'https://example.com/event.png',
    location: 'Centro',
    hostName: 'Host',
    message: 'Bora sim',
    tags: const ['show'],
    inviterName: 'Ana',
  );
}

AppData _buildAppData({
  required EnvironmentType environmentType,
}) {
  final platformType = PlatformTypeValue()..parse(AppType.web.name);
  final hostname = environmentType == EnvironmentType.landlord
      ? 'landlord.belluga.space'
      : 'guarappari.belluga.space';
  return buildAppDataFromInitialization(
    remoteData: {
      'name': 'Test',
      'type': environmentType.name,
      'main_domain': 'https://$hostname',
      'domains': ['https://$hostname'],
      'app_domains': const [],
      'theme_data_settings': {
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
        'brightness_default': 'light',
      },
      'main_color': '#4FA0E3',
      'tenant_id': 'tenant-1',
      'telemetry': {'trackers': []},
    },
    localInfo: {
      'platformType': platformType,
      'hostname': hostname,
      'href': 'https://$hostname',
      'port': null,
      'device': 'test-device',
    },
  );
}
