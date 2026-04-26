import 'package:belluga_now/testing/domain_factories.dart';
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
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_type_value.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
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
import 'package:belluga_now/testing/invite_model_factory.dart';

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

  test('select occurrence uses the selected occurrence start and end pair', () {
    final controller = ImmersiveEventDetailController(
      userEventsRepository: _FakeUserEventsRepository(),
      invitesRepository: _FakeInvitesRepository(),
      authRepository: _FakeAuthRepository(authorized: true),
    );
    final firstStart = DateTime(2026, 3, 15, 20);
    final secondStart = DateTime(2026, 3, 16, 9);
    final secondEnd = DateTime(2026, 3, 16, 14);
    final secondOccurrence = _buildOccurrence(
      id: 'occurrence-second',
      start: secondStart,
      end: secondEnd,
    );
    final event = _buildEvent(
      occurrences: [
        _buildOccurrence(
          id: 'occurrence-first',
          start: firstStart,
          end: DateTime(2026, 3, 15, 22),
          isSelected: true,
        ),
        secondOccurrence,
      ],
    );

    controller.init(event);
    controller.selectOccurrence(event, secondOccurrence);

    final selectedEvent = controller.eventStreamValue.value;
    expect(selectedEvent?.dateTimeStart.value, secondStart);
    expect(selectedEvent?.dateTimeEnd?.value, secondEnd);
    expect(selectedEvent?.selectedOccurrenceId, 'occurrence-second');
  });
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
      confirmedEventIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
    defaultValue: const <UserEventsRepositoryContractPrimString>{},
  );

  int confirmCalls = 0;
  final Set<String> _confirmedIds = <String>{};

  @override
  Future<void> confirmEventAttendance(
      UserEventsRepositoryContractPrimString eventId) async {
    confirmCalls += 1;
    _confirmedIds.add(eventId.value);
    confirmedEventIdsStream.addValue(
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
  UserEventsRepositoryContractPrimBool isEventConfirmed(
    UserEventsRepositoryContractPrimString eventId,
  ) =>
      userEventsRepoBool(
        _confirmedIds.contains(eventId.value),
        defaultValue: false,
        isRequired: true,
      );

  @override
  Future<void> refreshConfirmedEventIds() async {
    confirmedEventIdsStream.addValue(
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
      UserEventsRepositoryContractPrimString eventId) async {
    _confirmedIds.remove(eventId.value);
    confirmedEventIdsStream.addValue(
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
  int acceptInviteCalls = 0;
  @override
  Future<InviteAcceptResult> acceptInvite(
      InvitesRepositoryContractPrimString inviteId) async {
    acceptInviteCalls += 1;
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
      InvitesRepositoryContractPrimString code) async {
    acceptInviteCalls += 1;
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
    return buildInviteShareCodeResult(code: 'CODE123', eventId: eventId.value);
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
  Future<List<SentInviteStatus>> getSentInvitesForEvent(
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
  Future<void> sendInvites(InvitesRepositoryContractPrimString eventId,
      InviteRecipients recipients,
      {InvitesRepositoryContractPrimString? occurrenceId,
      InvitesRepositoryContractPrimString? message}) async {}
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
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
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
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> updateUser(
      UserCustomData data) async {}

  @override
  String get userToken => authorized ? 'token' : '';
}

EventModel _buildEvent({
  List<EventOccurrenceOption> occurrences = const [],
}) {
  return eventModelFromRaw(
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
    artists: const [],
    occurrences: occurrences,
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

EventOccurrenceOption _buildOccurrence({
  required String id,
  required DateTime start,
  DateTime? end,
  bool isSelected = false,
}) {
  final endValue = DomainOptionalDateTimeValue()..parse(end?.toIso8601String());

  return EventOccurrenceOption(
    occurrenceIdValue: EventLinkedAccountProfileTextValue(id),
    occurrenceSlugValue: EventLinkedAccountProfileTextValue('$id-slug'),
    dateTimeStartValue: DateTimeValue(isRequired: true)
      ..parse(start.toIso8601String()),
    dateTimeEndValue: endValue,
    isSelectedValue: EventOccurrenceFlagValue()..parse(isSelected.toString()),
    hasLocationOverrideValue: EventOccurrenceFlagValue()..parse('false'),
    programmingCountValue: EventProgrammingCountValue()..parse('0'),
  );
}

InviteModel _buildInviteForEvent({
  required String id,
  required String eventId,
}) {
  return buildInviteModelFromPrimitives(
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
