import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';
import 'package:belluga_now/domain/venue_event/projections/venue_event_resume.dart';
import 'package:belluga_now/presentation/tenant_public/schedule/screens/immersive_event_detail/controllers/immersive_event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/html_content_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';

void main() {
  test(
      'anonymous confirm attendance requires authentication and does not persist',
      () async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    final controller = ImmersiveEventDetailController(
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      authRepository: _FakeAuthRepository(authorized: false),
    );

    controller.init(_buildEvent());

    final result = await controller.confirmAttendance();

    expect(result, AttendanceConfirmationResult.requiresAuthentication);
    expect(userEventsRepository.confirmCalls, 0);
    expect(invitesRepository.acceptInviteCalls, 0);
    expect(invitesRepository.acceptShareCodeCalls, 0);
    expect(controller.isLoadingStreamValue.value, isFalse);
  });

  test('authenticated confirm attendance persists and updates state', () async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    final controller = ImmersiveEventDetailController(
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      authRepository: _FakeAuthRepository(authorized: true),
    );

    controller.init(_buildEvent());

    final result = await controller.confirmAttendance();

    expect(result, AttendanceConfirmationResult.confirmed);
    expect(userEventsRepository.confirmCalls, 1);
    expect(invitesRepository.acceptInviteCalls, 0);
    expect(invitesRepository.acceptShareCodeCalls, 0);
    expect(controller.isConfirmedStreamValue.value, isTrue);
    expect(controller.missionStreamValue.value, isNotNull);
  });

  test('event detail exposes pending invites only for current event', () async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    invitesRepository.pendingInvitesStreamValue.addValue([
      _buildInviteForEvent(
        id: 'invite-current-event',
        eventId: '507f1f77bcf86cd799439011',
      ),
      _buildInviteForEvent(
        id: 'invite-other-event',
        eventId: '507f1f77bcf86cd799439012',
      ),
    ]);
    final controller = ImmersiveEventDetailController(
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      authRepository: _FakeAuthRepository(authorized: true),
    );

    controller.init(_buildEvent());

    expect(controller.receivedInvitesStreamValue.value, hasLength(1));
    expect(
      controller.receivedInvitesStreamValue.value.first.id,
      'invite-current-event',
    );
    expect(
      controller.receivedInvitesStreamValue.value.first.eventId,
      '507f1f77bcf86cd799439011',
    );
  });
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<String>> confirmedEventIdsStream =
      StreamValue<Set<String>>(defaultValue: <String>{});

  int confirmCalls = 0;
  final Set<String> _confirmedIds = <String>{};

  @override
  Future<void> confirmEventAttendance(String eventId) async {
    confirmCalls += 1;
    _confirmedIds.add(eventId);
    confirmedEventIdsStream.addValue(Set<String>.from(_confirmedIds));
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  bool isEventConfirmed(String eventId) => _confirmedIds.contains(eventId);

  @override
  Future<void> refreshConfirmedEventIds() async {
    confirmedEventIdsStream.addValue(Set<String>.from(_confirmedIds));
  }

  @override
  Future<void> unconfirmEventAttendance(String eventId) async {
    _confirmedIds.remove(eventId);
    confirmedEventIdsStream.addValue(Set<String>.from(_confirmedIds));
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  int acceptInviteCalls = 0;
  int acceptShareCodeCalls = 0;

  @override
  Future<InviteAcceptResult> acceptInvite(String inviteId) async {
    acceptInviteCalls += 1;
    return buildInviteAcceptResult(
      inviteId: inviteId,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteAcceptResult> acceptShareCode(String code) async {
    acceptShareCodeCalls += 1;
    return buildInviteAcceptResult(
      inviteId: code,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.openAppToContinue,
      supersededInviteIds: const [],
    );
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required String eventId,
    String? occurrenceId,
    String? accountProfileId,
  }) async {
    return InviteShareCodeResult(code: 'CODE123', eventId: eventId);
  }

  @override
  Future<InviteDeclineResult> declineInvite(String inviteId) async {
    return InviteDeclineResult(
      inviteId: inviteId,
      status: 'declined',
      groupHasOtherPending: false,
    );
  }

  @override
  Future<List<InviteModel>> fetchInvites(
      {int page = 1, int pageSize = 20}) async {
    return const <InviteModel>[];
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    return const InviteRuntimeSettings(
      tenantId: null,
      limits: {},
      cooldowns: {},
      overQuotaMessage: null,
    );
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForEvent(String eventId) async {
    return const <SentInviteStatus>[];
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    List<ContactModel> contacts,
  ) async {
    return const <InviteContactMatch>[];
  }

  @override
  Future<void> sendInvites(
    String eventId,
    List<EventFriendResume> recipients, {
    String? occurrenceId,
    String? message,
  }) async {}
}

class _FakeAuthRepository extends AuthRepositoryContract {
  _FakeAuthRepository({required this.authorized});

  final bool authorized;

  @override
  Object get backend => Object();

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> createNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => authorized ? 'user-id' : null;

  @override
  Future<void> init() async {}

  @override
  bool get isAuthorized => authorized;

  @override
  bool get isUserLoggedIn => authorized;

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {}

  @override
  void setUserToken(String? token) {}

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {}

  @override
  Future<void> updateUser(Map<String, Object?> data) async {}

  @override
  String get userToken => authorized ? 'token' : '';
}

EventModel _buildEvent() {
  return EventModel(
    id: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
    slugValue: SlugValue()..parse('evento-de-teste'),
    type: EventTypeModel(
      id: EventTypeIdValue()..parse('show'),
      name: TitleValue()..parse('Show tipo'),
      slug: SlugValue()..parse('show'),
      description: DescriptionValue()..parse('Descricao longa do tipo.'),
      icon: SlugValue()..parse('music'),
      color: ColorValue(defaultValue: Colors.blue)..parse('#3366FF'),
    ),
    title: TitleValue()..parse('Evento de Teste'),
    content: HTMLContentValue()..parse('Descricao longa do evento para teste.'),
    location: DescriptionValue()..parse('Local muito legal para teste.'),
    venue: null,
    thumb: ThumbModel.fromPrimitives(url: 'https://example.com/event.png'),
    dateTimeStart: DateTimeValue(isRequired: true)
      ..parse(DateTime(2026, 3, 15, 20).toIso8601String()),
    dateTimeEnd: null,
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

InviteModel _buildInviteForEvent({
  required String id,
  required String eventId,
}) {
  return InviteModel.fromPrimitives(
    id: id,
    eventId: eventId,
    eventName: 'Evento $id',
    eventDateTime: DateTime(2026, 3, 15, 20),
    eventImageUrl: 'https://example.com/$id.png',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Convite $id',
    tags: const ['show'],
    inviterName: 'Convidador',
  );
}
