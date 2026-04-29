import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_id_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:belluga_now/testing/invite_materialize_result_builder.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

class _TrackedEvent {
  _TrackedEvent({
    required this.event,
    required this.eventName,
    required this.properties,
  });

  final EventTrackerEvents event;
  final String? eventName;
  final Map<String, dynamic>? properties;
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  final List<_TrackedEvent> loggedEvents = [];
  final List<_TrackedEvent> startedEvents = [];
  int _seed = 0;

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    loggedEvents.add(
      _TrackedEvent(
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
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    startedEvents.add(
      _TrackedEvent(
        event: event,
        eventName: eventName?.value,
        properties: properties == null
            ? null
            : TelemetryPropertiesCodec.toRawMap(properties),
      ),
    );
    return EventTrackerTimedEventHandle('handle-${_seed++}');
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async {
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async {
    return telemetryRepoBool(true);
  }

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async =>
      telemetryRepoBool(true);
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({
    required List<InviteModel> initialInvites,
    this.previewInvite,
    this.materializedInviteId,
  }) : _invites = List<InviteModel>.from(initialInvites);

  final List<InviteModel> _invites;
  final InviteModel? previewInvite;
  final String? materializedInviteId;
  final List<String> materializedShareCodes = <String>[];
  final List<String> previewedShareCodes = <String>[];
  final List<String> acceptedInviteIds = <String>[];
  final List<String> declinedInviteIds = <String>[];

  @override
  Future<List<InviteModel>> fetchInvites(
          {InvitesRepositoryContractPrimInt? page,
          InvitesRepositoryContractPrimInt? pageSize}) async =>
      List<InviteModel>.from(_invites);

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
      (() {
        acceptedInviteIds.add(inviteId.value);
        _removeInvite(inviteId.value);
        pendingInvitesStreamValue.addValue(List<InviteModel>.from(_invites));
        return buildInviteAcceptResult(
          inviteId: inviteId.value,
          status: 'accepted',
          creditedAcceptance: true,
          attendancePolicy: 'free_confirmation_only',
          nextStep: InviteNextStep.freeConfirmationCreated,
          supersededInviteIds: const [],
        );
      })();

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
          InvitesRepositoryContractPrimString code) async =>
      (() {
        acceptedInviteIds.add('mock-${code.value}');
        return buildInviteAcceptResult(
          inviteId: 'mock-${code.value}',
          status: 'accepted',
          creditedAcceptance: true,
          attendancePolicy: 'free_confirmation_only',
          nextStep: InviteNextStep.freeConfirmationCreated,
          supersededInviteIds: const [],
        );
      })();

  @override
  Future<InviteDeclineResult> declineInvite(
          InvitesRepositoryContractPrimString inviteId) async =>
      (() {
        declinedInviteIds.add(inviteId.value);
        _removeInvite(inviteId.value);
        pendingInvitesStreamValue.addValue(List<InviteModel>.from(_invites));
        return buildInviteDeclineResult(
          inviteId: inviteId.value,
          status: 'declined',
          groupHasOtherPending: false,
        );
      })();

  @override
  Future<InviteMaterializeResult> materializeShareCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    materializedShareCodes.add(code.value);
    return buildInviteMaterializeResult(
      inviteId: materializedInviteId ?? '',
      status: materializedInviteId == null ? 'expired' : 'pending',
      creditedAcceptance: false,
      attendancePolicy: 'free_confirmation_only',
    );
  }

  @override
  Future<InviteModel?> previewShareCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    previewedShareCodes.add(code.value);
    return previewInvite;
  }

  void _removeInvite(String inviteId) {
    final inviteIdValue = InviteIdValue()..parse(inviteId);
    _invites.removeWhere(
      (invite) =>
          invite.id == inviteId || invite.containsInviteId(inviteIdValue),
    );
  }

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
        code: 'CODE123',
        eventId: eventId.value,
        occurrenceId: occurrenceId?.value,
      );

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventSlug,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    InvitesRepositoryContractPrimString eventSlug,
  ) async =>
      const [];
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const {},
  );

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId,
  ) async {}

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId,
  ) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {}

  @override
  UserEventsRepositoryContractPrimBool isEventConfirmed(
    UserEventsRepositoryContractPrimString eventId,
  ) =>
      userEventsRepoBool(false, defaultValue: false, isRequired: true);
}

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({required this.authorized});

  final bool authorized;

  @override
  Object get backend => Object();

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  String get userToken => authorized ? 'token' : '';

  @override
  bool get isUserLoggedIn => authorized;

  @override
  bool get isAuthorized => authorized;

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => authorized ? 'user-id' : null;

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

InviteModel _buildInvite(String id) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: 'event-$id',
    eventName: 'Event $id',
    eventDateTime: DateTime(2025, 1, 1, 18),
    eventImageUrl: 'https://example.com/$id.jpg',
    location: 'Guarapari',
    hostName: 'Host $id',
    message: 'Invite $id',
    tags: const ['music'],
    inviterName: 'Inviter $id',
  );
}

void main() {
  test('invite_opened fires when the top invite changes', () async {
    final telemetry = _FakeTelemetryRepository();
    final invites = [_buildInvite('1'), _buildInvite('2')];
    final repository = _FakeInvitesRepository(initialInvites: invites);
    final userEventsRepository = _FakeUserEventsRepository();
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: userEventsRepository,
      telemetryRepository: telemetry,
    );

    await controller.init();
    await Future<void>.delayed(Duration.zero);

    expect(telemetry.startedEvents.length, 1);
    expect(telemetry.startedEvents.first.eventName, 'invite_opened');
    expect(
      telemetry.startedEvents.first.properties?['event_id'],
      'event-1',
    );

    controller.removeInvite();
    await Future<void>.delayed(Duration.zero);

    expect(telemetry.startedEvents.length, 2);
    expect(
      telemetry.startedEvents[1].properties?['event_id'],
      'event-2',
    );

    await controller.onDispose();
  });

  test('authenticated init resolves share-code preview without acceptance',
      () async {
    final repository = _FakeInvitesRepository(
      initialInvites: [_buildInvite('preview')],
      previewInvite: _buildInvite('preview'),
      materializedInviteId: 'preview',
    );
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
    );

    await controller.init(shareCode: 'SHARE-ABC');

    expect(repository.materializedShareCodes, ['SHARE-ABC']);
    expect(repository.previewedShareCodes, isEmpty);
    expect(controller.pendingInvitesStreamValue.value, hasLength(1));
    expect(controller.pendingInvitesStreamValue.value.first.id, 'preview');
    expect(controller.displayInvitesStreamValue.value.first.id, 'preview');
    expect(controller.authRequiredForDecisionStreamValue.value, isFalse);
    await controller.onDispose();
  });

  test('unauthenticated init resolves share-code preview without acceptance',
      () async {
    final repository = _FakeInvitesRepository(
      initialInvites: [_buildInvite('1')],
      previewInvite: _buildInvite('preview'),
    );
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: _FakeAuthRepository(authorized: false),
    );

    await controller.init(shareCode: 'SHARE-ABC');

    expect(repository.previewedShareCodes, ['SHARE-ABC']);
    expect(repository.materializedShareCodes, isEmpty);
    expect(controller.displayInvitesStreamValue.value, hasLength(1));
    expect(controller.displayInvitesStreamValue.value.first.id, 'preview');
    expect(controller.authRequiredForDecisionStreamValue.value, isFalse);
    await controller.onDispose();
  });

  test(
      'unauthenticated decision uses canonical invite accept (anonymous conversion)',
      () async {
    final repository = _FakeInvitesRepository(
      initialInvites: [_buildInvite('preview')],
      previewInvite: _buildInvite('preview'),
      materializedInviteId: 'preview',
    );
    final telemetry = _FakeTelemetryRepository();
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: telemetry,
      authRepository: _FakeAuthRepository(authorized: false),
    );

    await controller.init(shareCode: 'SHARE-ABC');
    await controller.requestDecision(InviteDecision.accepted);

    expect(repository.previewedShareCodes, ['SHARE-ABC']);
    // Repository.acceptInvite should be called even while unauthorized
    expect(repository.acceptedInviteIds, ['preview']);
    final acceptedEvent = telemetry.loggedEvents.singleWhere(
      (event) => event.eventName == 'app_anonymous_invite_accepted',
    );
    expect(acceptedEvent.properties?['code'], 'SHARE-ABC');
    expect(acceptedEvent.properties?['event_id'], 'event-preview');
    await controller.onDispose();
  });

  test(
      'failed share materialization does not fall back to unrelated pending invites',
      () async {
    final repository = _FakeInvitesRepository(
      initialInvites: [_buildInvite('unrelated')],
      materializedInviteId: null,
    );
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: _FakeAuthRepository(authorized: true),
    );

    await controller.init(shareCode: 'SHARE-ABC');

    expect(repository.materializedShareCodes, ['SHARE-ABC']);
    expect(controller.pendingInvitesStreamValue.value, isEmpty);
    expect(controller.displayInvitesStreamValue.value, isEmpty);
    await controller.onDispose();
  });

  test('accepted decision uses canonical invite accept after materialization',
      () async {
    final repository = _FakeInvitesRepository(
      initialInvites: [_buildInvite('preview')],
      materializedInviteId: 'preview',
    );
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: _FakeAuthRepository(authorized: true),
    );

    await controller.init(shareCode: 'SHARE-ABC');
    await controller.requestDecision(InviteDecision.accepted);

    expect(repository.materializedShareCodes, ['SHARE-ABC']);
    expect(repository.acceptedInviteIds, ['preview']);
    await controller.onDispose();
  });

  test('declined decision uses canonical invite decline after materialization',
      () async {
    final repository = _FakeInvitesRepository(
      initialInvites: [_buildInvite('preview')],
      materializedInviteId: 'preview',
    );
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: _FakeAuthRepository(authorized: true),
    );

    await controller.init(shareCode: 'SHARE-ABC');
    await controller.requestDecision(InviteDecision.declined);

    expect(repository.materializedShareCodes, ['SHARE-ABC']);
    expect(repository.declinedInviteIds, ['preview']);
    expect(controller.displayInvitesStreamValue.value, isEmpty);
    await controller.onDispose();
  });
}
