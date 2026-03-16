import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decision.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_flow_screen/controllers/invite_flow_controller.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

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
  final List<_TrackedEvent> startedEvents = [];
  int _seed = 0;

  @override
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    return true;
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    startedEvents.add(
      _TrackedEvent(
        event: event,
        eventName: eventName,
        properties: properties,
      ),
    );
    return EventTrackerTimedEventHandle('handle-${_seed++}');
  }

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) async {
    return true;
  }

  @override
  Future<bool> flushTimedEvents() async {
    return true;
  }

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<bool> mergeIdentity({required String previousUserId}) async => true;
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({
    required List<InviteModel> initialInvites,
    this.previewInvite,
  }) : _initialInvites = initialInvites;

  final List<InviteModel> _initialInvites;
  final InviteModel? previewInvite;
  final List<String> acceptedShareCodes = <String>[];
  final List<String> previewedShareCodes = <String>[];
  final List<String> acceptedInviteIds = <String>[];
  final List<String> declinedInviteIds = <String>[];

  @override
  Future<List<InviteModel>> fetchInvites(
          {int page = 1, int pageSize = 20}) async =>
      _initialInvites;

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      const InviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async => (() {
        acceptedInviteIds.add(inviteId);
        return InviteAcceptResult(
          inviteId: inviteId,
          status: 'accepted',
          creditedAcceptance: true,
          attendancePolicy: 'free_confirmation_only',
          nextStep: InviteNextStep.freeConfirmationCreated,
          supersededInviteIds: const [],
        );
      })();

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async => (() {
        declinedInviteIds.add(inviteId);
        return InviteDeclineResult(
          inviteId: inviteId,
          status: 'declined',
          groupHasOtherPending: false,
        );
      })();

  @override
  Future<InviteAcceptResult> acceptShareCode(String code) async {
    acceptedShareCodes.add(code);
    return InviteAcceptResult(
      inviteId: code,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.openAppToContinue,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteModel?> previewShareCode(String code) async {
    previewedShareCodes.add(code);
    return previewInvite;
  }

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
      InviteShareCodeResult(
        code: 'CODE123',
        eventId: eventId,
        occurrenceId: occurrenceId,
      );

  @override
  Future<void> sendInvites(
    String eventSlug,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
    String eventSlug,
  ) async =>
      const [];
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: const {});

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<void> confirmEventAttendance(String eventId) async {}

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {}

  @override
  Future<void> refreshConfirmedEventIds() async {}

  @override
  bool isEventConfirmed(String eventId) => false;
}

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({required this.authorized});

  final bool authorized;

  @override
  Object get backend => Object();

  @override
  void setUserToken(String? token) {}

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
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUser(Map<String, Object?> data) async {}
}

InviteModel _buildInvite(String id) {
  return InviteModel.fromPrimitives(
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

InviteModel _buildInviteWithoutInviter(String id) {
  return InviteModel.fromPrimitives(
    id: id,
    eventId: 'event-$id',
    eventName: 'Event $id',
    eventDateTime: DateTime(2025, 1, 1, 18),
    eventImageUrl: 'https://example.com/$id.jpg',
    location: 'Guarapari',
    hostName: 'Host $id',
    message: 'Invite $id',
    tags: const ['music'],
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
      initialInvites: [_buildInvite('1')],
      previewInvite: _buildInvite('preview'),
    );
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
    );

    await controller.init(shareCode: 'SHARE-ABC');

    expect(repository.previewedShareCodes, ['SHARE-ABC']);
    expect(repository.acceptedShareCodes, isEmpty);
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
    expect(repository.acceptedShareCodes, isEmpty);
    expect(controller.displayInvitesStreamValue.value, hasLength(1));
    expect(controller.displayInvitesStreamValue.value.first.id, 'preview');
    expect(controller.authRequiredForDecisionStreamValue.value, isTrue);
    await controller.onDispose();
  });

  test(
      'accepted decision falls back to acceptShareCode when preview has no invite id',
      () async {
    final repository = _FakeInvitesRepository(
      initialInvites: const [],
      previewInvite: _buildInviteWithoutInviter('preview'),
    );
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: _FakeAuthRepository(authorized: true),
    );

    await controller.init(shareCode: 'SHARE-ABC');
    await controller.requestDecision(InviteDecision.accepted);

    expect(repository.previewedShareCodes, ['SHARE-ABC']);
    expect(repository.acceptedShareCodes, ['SHARE-ABC']);
    expect(repository.acceptedInviteIds, isEmpty);
    await controller.onDispose();
  });

  test('declined decision without invite id dismisses preview locally',
      () async {
    final repository = _FakeInvitesRepository(
      initialInvites: const [],
      previewInvite: _buildInviteWithoutInviter('preview'),
    );
    final controller = InviteFlowScreenController(
      repository: repository,
      userEventsRepository: _FakeUserEventsRepository(),
      telemetryRepository: _FakeTelemetryRepository(),
      authRepository: _FakeAuthRepository(authorized: true),
    );

    await controller.init(shareCode: 'SHARE-ABC');
    await controller.requestDecision(InviteDecision.declined);

    expect(repository.declinedInviteIds, isEmpty);
    expect(controller.displayInvitesStreamValue.value, isEmpty);
    await controller.onDispose();
  });
}
