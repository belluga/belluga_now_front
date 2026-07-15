import 'dart:async';

import 'package:belluga_now/application/schedule/event_selected_occurrence_projection.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_events_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_events_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_occurrence_option.dart';
import 'package:belluga_now/domain/schedule/event_programming_item.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/event_type_model.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_order_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_is_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_occurrence_values.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_total_confirmed_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_type_id_value.dart';
import 'package:belluga_now/domain/thumb/enums/thumb_types.dart';
import 'package:belluga_now/domain/thumb/thumb_model.dart';
import 'package:belluga_now/domain/value_objects/color_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/venue_event/value_objects/venue_event_tag_value.dart';
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
    },
  );

  test('authenticated confirm attendance persists and updates state', () async {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    _linkRepositories(userEventsRepository, invitesRepository);
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
  });

  test('anonymous linked profile favorite requires authentication', () {
    final userEventsRepository = _FakeUserEventsRepository();
    final invitesRepository = _FakeInvitesRepository();
    final accountProfilesRepository = _FakeAccountProfilesRepository();
    final controller = ImmersiveEventDetailController(
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      authRepository: _FakeAuthRepository(authorized: false),
      accountProfilesRepository: accountProfilesRepository,
    );

    final result = controller.toggleLinkedProfileFavorite('artist-1');

    expect(result, LinkedProfileFavoriteToggleOutcome.requiresAuthentication);
    expect(accountProfilesRepository.toggleFavoriteCalls, 0);
  });

  test('confirm attendance drops duplicate requests while pending', () async {
    final userEventsRepository = _FakeUserEventsRepository()
      ..confirmGate = Completer<void>();
    final invitesRepository = _FakeInvitesRepository();
    _linkRepositories(userEventsRepository, invitesRepository);
    final controller = ImmersiveEventDetailController(
      userEventsRepository: userEventsRepository,
      invitesRepository: invitesRepository,
      authRepository: _FakeAuthRepository(authorized: true),
    );

    controller.init(_buildEvent());

    final firstResult = controller.confirmAttendance();
    await Future<void>.delayed(Duration.zero);

    expect(controller.isConfirmationStateLoadingStreamValue.value, isTrue);
    expect(userEventsRepository.confirmCalls, 1);

    final duplicateResult = await controller.confirmAttendance();

    expect(duplicateResult, AttendanceConfirmationResult.skipped);
    expect(userEventsRepository.confirmCalls, 1);

    userEventsRepository.confirmGate!.complete();

    expect(await firstResult, AttendanceConfirmationResult.confirmed);
    expect(controller.isConfirmationStateLoadingStreamValue.value, isFalse);
    expect(controller.isConfirmedStreamValue.value, isTrue);
  });

  test(
    'authenticated confirm attendance clears superseded pending invite state',
    () async {
      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      _linkRepositories(userEventsRepository, invitesRepository);
      final invite = _buildInviteForEvent(
        id: 'pending-direct-confirm',
        eventId: '507f1f77bcf86cd799439011',
      );
      invitesRepository.pendingInvitesStreamValue.addValue([invite]);
      invitesRepository.fetchInvitesResult = [invite];
      invitesRepository.setShareCodeSessionContext(
        code: invitesRepoString(
          'SHARE-ABC',
          defaultValue: '',
          isRequired: true,
        ),
        invite: invite,
      );
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      );

      controller.init(_buildEvent());
      await Future<void>.delayed(Duration.zero);
      expect(controller.receivedInvitesStreamValue.value, hasLength(1));

      invitesRepository.fetchInvitesResult = const <InviteModel>[];
      final result = await controller.confirmAttendance();

      expect(result, AttendanceConfirmationResult.confirmed);
      expect(invitesRepository.fetchInvitesCalls, 1);
      expect(invitesRepository.pendingInvitesStreamValue.value, isEmpty);
      expect(
        invitesRepository.shareCodeSessionContextStreamValue.value,
        isNull,
      );
      expect(controller.receivedInvitesStreamValue.value, isEmpty);
    },
  );

  test(
    'event detail init rehydrates controller state even when repository already tracks the same selected occurrence',
    () async {
      final userEventsRepository = _FakeUserEventsRepository();
      await userEventsRepository.confirmEventAttendance(
        userEventsRepoString(
          '507f1f77bcf86cd799439011',
          defaultValue: '',
          isRequired: true,
        ),
        occurrenceId: userEventsRepoString(
          '507f1f77bcf86cd799439012',
          defaultValue: '',
          isRequired: true,
        ),
      );
      final invitesRepository = _FakeInvitesRepository();
      final event = _buildEvent();
      invitesRepository.setImmersiveSelectedEvent(event);
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      );

      controller.init(event);

      expect(
        controller.eventStreamValue.value?.selectedOccurrenceId,
        event.selectedOccurrenceId,
      );
      expect(controller.isConfirmedStreamValue.value, isTrue);
      expect(userEventsRepository.refreshConfirmedOccurrenceIdsCalls, 1);
    },
  );

  test(
    'event detail init replaces stale same-target profile groups with route-resolved event',
    () {
      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      final staleEvent = _buildEvent(
        profileGroups: [
          _buildProfileGroup(
            id: 'palco-sexta',
            label: 'Palco Sexta',
            order: 0,
            profiles: [
              _buildLinkedProfile(
                id: 'profile-band',
                displayName: 'Banda Sexta',
                profileType: 'banda',
                slug: 'banda-sexta',
              ),
            ],
          ),
        ],
      );
      final freshEvent = _buildEvent(
        profileGroups: [
          _buildProfileGroup(
            id: 'palco-sabado',
            label: 'Palco Sabado',
            order: 0,
            profiles: [
              _buildLinkedProfile(
                id: 'profile-band-sabado',
                displayName: 'Banda Sabado',
                profileType: 'banda',
                slug: 'banda-sabado',
              ),
            ],
          ),
        ],
      );
      invitesRepository.setImmersiveSelectedEvent(staleEvent);
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      );

      controller.init(freshEvent);

      expect(
        controller.eventStreamValue.value?.profileGroups.map(
          (group) => group.id,
        ),
        ['palco-sabado'],
      );
    },
  );

  test(
    'event detail init replaces stale same-target occurrence tags with route-resolved event',
    () {
      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      final staleEvent = _buildEvent(
        tags: const ['Showcase'],
        occurrences: [
          _buildOccurrence(
            id: '507f1f77bcf86cd799439012',
            start: DateTime(2026, 3, 15, 20),
            end: DateTime(2026, 3, 15, 22),
            isSelected: true,
            tags: const ['Showcase'],
          ),
        ],
      );
      final freshEvent = _buildEvent(
        tags: const ['Instrumental'],
        occurrences: [
          _buildOccurrence(
            id: '507f1f77bcf86cd799439012',
            start: DateTime(2026, 3, 15, 20),
            end: DateTime(2026, 3, 15, 22),
            isSelected: true,
            tags: const ['Instrumental'],
          ),
        ],
      );
      invitesRepository.setImmersiveSelectedEvent(staleEvent);
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      );

      controller.init(freshEvent);

      expect(controller.eventStreamValue.value?.tags.map((tag) => tag.value), [
        'Instrumental',
      ]);
    },
  );

  test(
    'event detail init refreshes sent invite summary for selected occurrence',
    () async {
      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      );

      controller.init(_buildEvent());
      await pumpEventQueue();

      expect(invitesRepository.sentSummaryRefreshes, [
        {
          'occurrence_id': '507f1f77bcf86cd799439012',
          'event_id': '507f1f77bcf86cd799439011',
          'preview_limit': null,
        },
      ]);
      expect(invitesRepository.sentStatusRefreshes, isEmpty);
    },
  );

  test(
    'event detail init does not refresh confirmed ids on entry and consumes repository cache',
    () async {
      final userEventsRepository = _FakeUserEventsRepository();
      await userEventsRepository.confirmEventAttendance(
        userEventsRepoString(
          '507f1f77bcf86cd799439011',
          defaultValue: '',
          isRequired: true,
        ),
        occurrenceId: userEventsRepoString(
          'occurrence-selected',
          defaultValue: '',
          isRequired: true,
        ),
      );
      userEventsRepository.refreshConfirmedOccurrenceIdsCalls = 0;
      final invitesRepository = _FakeInvitesRepository()
        ..pendingInvitesStreamValue.addValue([
          _buildInviteForEvent(
            id: 'stale-invite',
            eventId: '507f1f77bcf86cd799439011',
            occurrenceId: 'occurrence-selected',
          ),
        ]);
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      );

      controller.init(
        _buildEvent(
          occurrences: [
            _buildOccurrence(
              id: 'occurrence-selected',
              start: DateTime(2026, 3, 15, 20),
              isSelected: true,
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.isConfirmedStreamValue.value, isTrue);
      expect(controller.receivedInvitesStreamValue.value, isEmpty);
      expect(userEventsRepository.refreshConfirmedOccurrenceIdsCalls, 0);
    },
  );

  test(
    'event detail exposes pending invites only for selected occurrence',
    () async {
      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      final pendingInvites = [
        _buildInviteForEvent(
          id: 'invite-current-occurrence',
          eventId: '507f1f77bcf86cd799439011',
          occurrenceId: 'occurrence-selected',
        ),
        _buildInviteForEvent(
          id: 'invite-other-occurrence',
          eventId: '507f1f77bcf86cd799439011',
          occurrenceId: 'occurrence-other',
        ),
      ];
      invitesRepository.pendingInvitesStreamValue.addValue(pendingInvites);
      invitesRepository.fetchInvitesResult = pendingInvites;
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      );

      controller.init(
        _buildEvent(
          occurrences: [
            _buildOccurrence(
              id: 'occurrence-selected',
              start: DateTime(2026, 3, 15, 20),
              isSelected: true,
            ),
            _buildOccurrence(
              id: 'occurrence-other',
              start: DateTime(2026, 3, 16, 9),
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.receivedInvitesStreamValue.value, hasLength(1));
      expect(
        controller.receivedInvitesStreamValue.value.first.id,
        'invite-current-occurrence',
      );
      expect(
        controller.receivedInvitesStreamValue.value.first.occurrenceId,
        'occurrence-selected',
      );
    },
  );

  test(
    'event detail exposes share-code session context for selected occurrence',
    () async {
      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      invitesRepository.setShareCodeSessionContext(
        code: invitesRepoString(
          'SHARE-ABC',
          defaultValue: '',
          isRequired: true,
        ),
        invite: _buildInviteForEvent(
          id: 'session-preview',
          eventId: '507f1f77bcf86cd799439011',
          occurrenceId: 'occurrence-selected',
        ),
      );
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: false),
      );

      controller.init(
        _buildEvent(
          occurrences: [
            _buildOccurrence(
              id: 'occurrence-selected',
              start: DateTime(2026, 3, 15, 20),
              isSelected: true,
            ),
          ],
        ),
      );

      expect(controller.receivedInvitesStreamValue.value, hasLength(1));
      expect(
        controller.receivedInvitesStreamValue.value.single.id,
        'session-preview',
      );
      expect(controller.shareCodeForSelectedEvent(), 'SHARE-ABC');
      expect(
        controller.shareCodeForInvite(
          controller.receivedInvitesStreamValue.value.single,
        ),
        'SHARE-ABC',
      );
    },
  );

  test(
    'authenticated app session-context invite acceptance uses share-code endpoint',
    () async {
      final userEventsRepository = _FakeUserEventsRepository();
      final invitesRepository = _FakeInvitesRepository();
      _linkRepositories(userEventsRepository, invitesRepository);
      invitesRepository.setShareCodeSessionContext(
        code: invitesRepoString(
          'SHARE-ABC',
          defaultValue: '',
          isRequired: true,
        ),
        invite: _buildInviteForEvent(
          id: 'session-preview',
          eventId: '507f1f77bcf86cd799439011',
        ),
      );
      final controller = ImmersiveEventDetailController(
        userEventsRepository: userEventsRepository,
        invitesRepository: invitesRepository,
        authRepository: _FakeAuthRepository(authorized: true),
      );

      controller.init(_buildEvent());
      final result = await controller.acceptInvite('session-preview');

      expect(result.status, 'accepted');
      expect(invitesRepository.acceptInviteCalls, 0);
      expect(invitesRepository.acceptedShareCodes, ['SHARE-ABC']);
      expect(
        invitesRepository.shareCodeSessionContextStreamValue.value,
        isNull,
      );
    },
  );

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
    final profileGroups = [
      _buildProfileGroup(
        id: 'bandas-customizadas',
        label: 'Bandas Customizadas',
        order: 0,
        profiles: [
          _buildLinkedProfile(
            id: 'profile-alpha',
            displayName: 'Artista Alpha',
            profileType: 'tipo-alpha',
            slug: 'artista-alpha',
          ),
        ],
      ),
    ];
    final event = _buildEvent(
      profileGroups: profileGroups,
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
    expect(selectedEvent?.profileGroups.map((group) => group.label), [
      'Bandas Customizadas',
    ]);
    expect(
      selectedEvent?.profileGroups.single.profiles.single.displayName,
      'Artista Alpha',
    );
  });

  test(
    'select occurrence replaces visible taxonomy tags with occurrence tags',
    () {
      final controller = ImmersiveEventDetailController(
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      final secondOccurrence = _buildOccurrence(
        id: 'occurrence-second',
        start: DateTime(2026, 3, 16, 9),
        end: DateTime(2026, 3, 16, 14),
        tags: const ['Instrumental'],
      );
      final event = _buildEvent(
        tags: const ['Showcase'],
        occurrences: [
          _buildOccurrence(
            id: 'occurrence-first',
            start: DateTime(2026, 3, 15, 20),
            end: DateTime(2026, 3, 15, 22),
            isSelected: true,
            tags: const ['Showcase'],
          ),
          secondOccurrence,
        ],
      );

      controller.init(event);
      controller.selectOccurrence(event, secondOccurrence);

      expect(controller.eventStreamValue.value?.tags.map((tag) => tag.value), [
        'Instrumental',
      ]);
    },
  );

  test(
    'select occurrence preserves aggregate profile groups while selecting programming occurrence',
    () {
      final controller = ImmersiveEventDetailController(
        userEventsRepository: _FakeUserEventsRepository(),
        invitesRepository: _FakeInvitesRepository(),
        authRepository: _FakeAuthRepository(authorized: true),
      );
      final bandProfile = _buildLinkedProfile(
        id: 'profile-band',
        displayName: 'Banda Azul',
        profileType: 'banda',
        slug: 'banda-azul',
      );
      final exhibitorProfile = _buildLinkedProfile(
        id: 'profile-exhibitor',
        displayName: 'Expositor Sol',
        profileType: 'expositor',
        slug: 'expositor-sol',
      );
      final secondOccurrence = _buildOccurrence(
        id: 'occurrence-second',
        start: DateTime(2026, 3, 16, 16),
        profileGroups: [
          _buildProfileGroup(
            id: 'vila-expositores',
            label: 'Vila Expositores',
            order: 0,
            accountProfileIds: ['profile-exhibitor'],
          ),
        ],
      );
      final event = _buildEvent(
        linkedAccountProfiles: [bandProfile, exhibitorProfile],
        profileGroups: [
          _buildProfileGroup(
            id: 'palco-bandas',
            label: 'Palco Bandas',
            order: 0,
            accountProfileIds: ['profile-band'],
          ),
          _buildProfileGroup(
            id: 'vila-expositores',
            label: 'Vila Expositores',
            order: 1,
            accountProfileIds: ['profile-exhibitor'],
          ),
        ],
        occurrences: [
          _buildOccurrence(
            id: 'occurrence-first',
            start: DateTime(2026, 3, 15, 18),
            isSelected: true,
            profileGroups: [
              _buildProfileGroup(
                id: 'palco-bandas',
                label: 'Palco Bandas',
                order: 0,
                accountProfileIds: ['profile-band'],
              ),
            ],
          ),
          secondOccurrence,
        ],
      );

      controller.init(event);
      controller.selectOccurrence(event, secondOccurrence);

      final selectedEvent = controller.eventStreamValue.value;
      expect(selectedEvent?.selectedOccurrenceId, 'occurrence-second');
      expect(selectedEvent?.profileGroups.map((group) => group.label), [
        'Palco Bandas',
        'Vila Expositores',
      ]);
      expect(
        selectedEvent?.profileGroups
            .singleWhere((group) => group.label == 'Vila Expositores')
            .accountProfileIdValues
            .map((id) => id.value),
        ['profile-exhibitor'],
      );
      expect(
        selectedEvent?.profileGroups
            .singleWhere((group) => group.label == 'Palco Bandas')
            .accountProfileIdValues
            .map((id) => id.value),
        ['profile-band'],
      );
      expect(
        selectedEvent?.occurrences
            .singleWhere(
              (occurrence) => occurrence.occurrenceId == 'occurrence-second',
            )
            .profileGroups
            .single
            .accountProfileIdValues
            .map((id) => id.value),
        ['profile-exhibitor'],
      );
      expect(
        selectedEvent?.linkedAccountProfiles
            .singleWhere((profile) => profile.id == 'profile-exhibitor')
            .displayName,
        'Expositor Sol',
      );
    },
  );

  test(
    'selected occurrence projection can retarget an unselected event payload without refetching',
    () {
      final event = _buildEvent(
        tags: const ['Feira'],
        occurrences: [
          _buildOccurrence(
            id: 'occurrence-first',
            start: DateTime(2026, 3, 15, 18),
            isSelected: true,
            tags: const ['Feira'],
          ),
          _buildOccurrence(
            id: 'occurrence-second',
            start: DateTime(2026, 3, 16, 21),
            end: DateTime(2026, 3, 17, 1),
            tags: const ['Show'],
            programmingItems: [
              _buildProgrammingItem(time: '21:00', title: 'Headliner'),
            ],
          ),
        ],
        programmingItems: const [],
      );

      final projected = EventSelectedOccurrenceProjection.project(
        event,
        'occurrence-second',
      );

      expect(projected.selectedOccurrenceId, 'occurrence-second');
      expect(projected.dateTimeStart.value, DateTime(2026, 3, 16, 21));
      expect(projected.dateTimeEnd?.value, DateTime(2026, 3, 17, 1));
      expect(projected.programmingItems.map((item) => item.title), [
        'Headliner',
      ]);
      expect(projected.tags.map((tag) => tag.value), ['Show']);
    },
  );

  test(
    'selected occurrence projection aligns stale selected payload while keeping aggregate groups',
    () {
      final event = _buildEvent(
        tags: const ['Feira'],
        profileGroups: [
          _buildProfileGroup(
            id: 'bandas',
            label: 'Bandas',
            order: 0,
            accountProfileIds: ['profile-band'],
          ),
          _buildProfileGroup(
            id: 'expositores',
            label: 'Expositores',
            order: 1,
            accountProfileIds: ['profile-exhibitor'],
          ),
        ],
        occurrences: [
          _buildOccurrence(
            id: 'occurrence-first',
            start: DateTime(2026, 3, 15, 18),
            profileGroups: [
              _buildProfileGroup(
                id: 'bandas',
                label: 'Bandas',
                order: 0,
                accountProfileIds: ['profile-band'],
              ),
            ],
          ),
          _buildOccurrence(
            id: 'occurrence-second',
            start: DateTime(2026, 3, 16, 21),
            isSelected: true,
            tags: const ['Show'],
            programmingItems: [
              _buildProgrammingItem(time: '21:00', title: 'Headliner'),
            ],
            profileGroups: [
              _buildProfileGroup(
                id: 'expositores',
                label: 'Expositores',
                order: 1,
                accountProfileIds: ['profile-exhibitor'],
              ),
            ],
          ),
        ],
        programmingItems: const [],
      );

      final aligned = EventSelectedOccurrenceProjection.align(event);

      expect(aligned.selectedOccurrenceId, 'occurrence-second');
      expect(aligned.programmingItems.map((item) => item.title), ['Headliner']);
      expect(aligned.tags.map((tag) => tag.value), ['Show']);
      expect(aligned.profileGroups.map((group) => group.label), [
        'Bandas',
        'Expositores',
      ]);
    },
  );
}

class _FakeUserEventsRepository implements UserEventsRepositoryContract {
  @override
  void clearCurrentIdentityState() {}

  @override
  final StreamValue<Set<UserEventsRepositoryContractPrimString>>
  confirmedOccurrenceIdsStream =
      StreamValue<Set<UserEventsRepositoryContractPrimString>>(
        defaultValue: const <UserEventsRepositoryContractPrimString>{},
      );

  int confirmCalls = 0;
  int refreshConfirmedOccurrenceIdsCalls = 0;
  final Set<String> _confirmedIds = <String>{};
  void Function()? onRefreshConfirmedOccurrenceIds;
  Completer<void>? confirmGate;
  _FakeInvitesRepository? linkedInvitesRepository;

  @override
  Future<void> confirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {
    confirmCalls += 1;
    await confirmGate?.future;
    _confirmedIds.add(occurrenceId.value);
    await refreshConfirmedOccurrenceIds();
    await linkedInvitesRepository?.syncAfterAttendanceMutation(
      occurrenceId.value,
    );
  }

  @override
  Future<List<VenueEventResume>> fetchFeaturedEvents() async => const [];

  @override
  Future<List<VenueEventResume>> fetchMyEvents() async => const [];

  @override
  UserEventsRepositoryContractPrimBool isOccurrenceConfirmed(
    UserEventsRepositoryContractPrimString eventId,
  ) => userEventsRepoBool(
    _confirmedIds.contains(eventId.value),
    defaultValue: false,
    isRequired: true,
  );

  @override
  Future<void> refreshConfirmedOccurrenceIds() async {
    refreshConfirmedOccurrenceIdsCalls += 1;
    onRefreshConfirmedOccurrenceIds?.call();
    confirmedOccurrenceIdsStream.addValue(
      _confirmedIds
          .map(
            (value) =>
                userEventsRepoString(value, defaultValue: '', isRequired: true),
          )
          .toSet(),
    );
  }

  void confirmedOnRefresh(String occurrenceId) {
    _confirmedIds.add(occurrenceId);
  }

  @override
  Future<void> unconfirmEventAttendance(
    UserEventsRepositoryContractPrimString eventId, {
    required UserEventsRepositoryContractPrimString occurrenceId,
  }) async {
    _confirmedIds.remove(occurrenceId.value);
    await refreshConfirmedOccurrenceIds();
    await linkedInvitesRepository?.refreshPendingInvites();
  }

  Future<void> syncAfterInviteAcceptance(String occurrenceId) async {
    _confirmedIds.add(occurrenceId);
    await refreshConfirmedOccurrenceIds();
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  int acceptInviteCalls = 0;
  int fetchInvitesCalls = 0;
  final sentStatusRefreshes = <Map<String, Object?>>[];
  final sentSummaryRefreshes = <Map<String, Object?>>[];
  final List<String> acceptedShareCodes = <String>[];
  List<InviteModel> fetchInvitesResult = const <InviteModel>[];
  _FakeUserEventsRepository? linkedUserEventsRepository;

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async {
    acceptInviteCalls += 1;
    await refreshPendingInvites();
    final result = buildInviteAcceptResult(
      inviteId: inviteId.value,
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
    await _syncAcceptedOccurrence(_occurrenceIdForInviteId(inviteId.value));
    return result;
  }

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async {
    final occurrenceId = shareCodeSessionContextStreamValue.value?.occurrenceId;
    acceptedShareCodes.add(code.value);
    clearShareCodeSessionContext(code: code);
    await refreshPendingInvites();
    final result = buildInviteAcceptResult(
      inviteId: 'mock-${code.value}',
      status: 'accepted',
      creditedAcceptance: true,
      attendancePolicy: 'free_confirmation_only',
      nextStep: InviteNextStep.freeConfirmationCreated,
      supersededInviteIds: const [],
    );
    await _syncAcceptedOccurrence(occurrenceId);
    return result;
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    return buildInviteShareCodeResult(
      code: 'CODE123',
      eventId: eventId.value,
      occurrenceId: occurrenceId.value,
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
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    fetchInvitesCalls += 1;
    if ((page?.value ?? 1) == 1) {
      pendingInvitesStreamValue.addValue(fetchInvitesResult);
    }
    return fetchInvitesResult;
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
    InvitesRepositoryContractPrimString eventId,
  ) async {
    return const <SentInviteStatus>[];
  }

  @override
  Future<List<SentInviteStatus>> refreshSentInvitesForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    Iterable<InvitesRepositoryContractPrimString> recipientAccountProfileIds =
        const <InvitesRepositoryContractPrimString>[],
  }) async {
    sentStatusRefreshes.add({
      'occurrence_id': occurrenceId.value,
      'event_id': eventId?.value,
      if (recipientAccountProfileIds.isNotEmpty)
        'recipient_account_profile_ids': recipientAccountProfileIds
            .map((value) => value.value)
            .toList(),
    });
    return const <SentInviteStatus>[];
  }

  @override
  Future<SentInviteSummary> refreshSentInviteSummaryForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    InvitesRepositoryContractPrimInt? previewLimit,
  }) async {
    sentSummaryRefreshes.add({
      'occurrence_id': occurrenceId.value,
      'event_id': eventId?.value,
      'preview_limit': previewLimit?.value,
    });
    return SentInviteSummary.empty();
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    return const <InviteContactMatch>[];
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}

  Future<void> syncAfterAttendanceMutation(String occurrenceId) async {
    clearShareCodeSessionContext(
      occurrenceId: invitesRepoString(
        occurrenceId,
        defaultValue: '',
        isRequired: true,
      ),
    );
    await refreshPendingInvites();
  }

  String? _occurrenceIdForInviteId(String inviteId) {
    for (final invite in pendingInvitesStreamValue.value) {
      if (invite.id == inviteId) {
        return invite.occurrenceId;
      }
    }
    return null;
  }

  Future<void> _syncAcceptedOccurrence(String? occurrenceId) async {
    final normalized = occurrenceId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return;
    }
    await linkedUserEventsRepository?.syncAfterInviteAcceptance(normalized);
  }
}

void _linkRepositories(
  _FakeUserEventsRepository userEventsRepository,
  _FakeInvitesRepository invitesRepository,
) {
  userEventsRepository.linkedInvitesRepository = invitesRepository;
  invitesRepository.linkedUserEventsRepository = userEventsRepository;
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
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}

  @override
  String get userToken => authorized ? 'token' : '';
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  int toggleFavoriteCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async {
    return pagedAccountProfilesResultFromRaw(
      profiles: const <AccountProfileModel>[],
      hasMore: false,
    );
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async => null;

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    AccountProfilesRepositoryContractPrimInt? pageSize,
    List<AccountProfilesRepositoryContractPrimString>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) async => const <AccountProfileModel>[];

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    toggleFavoriteCalls += 1;
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(
      false,
      defaultValue: false,
    );
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() =>
      const <AccountProfileModel>[];
}

EventModel _buildEvent({
  List<EventOccurrenceOption> occurrences = const [],
  List<EventProfileGroup> profileGroups = const [],
  List<EventLinkedAccountProfile> linkedAccountProfiles =
      const <EventLinkedAccountProfile>[],
  List<EventProgrammingItem> programmingItems = const <EventProgrammingItem>[],
  List<String> tags = const <String>['show'],
}) {
  final resolvedOccurrences = occurrences.isEmpty
      ? [
          _buildOccurrence(
            id: '507f1f77bcf86cd799439012',
            start: DateTime(2026, 3, 15, 20),
            isSelected: true,
          ),
        ]
      : occurrences;

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
    linkedAccountProfiles: linkedAccountProfiles,
    profileGroups: profileGroups,
    occurrences: resolvedOccurrences,
    programmingItems: programmingItems,
    coordinate: null,
    tags: tags,
    isConfirmedValue: EventIsConfirmedValue()..parse('false'),
    confirmedAt: null,
    receivedInvites: null,
    sentInvites: null,
    friendsGoing: null,
    totalConfirmedValue: EventTotalConfirmedValue()..parse('0'),
  );
}

EventProfileGroup _buildProfileGroup({
  required String id,
  required String label,
  required int order,
  List<EventLinkedAccountProfile> profiles =
      const <EventLinkedAccountProfile>[],
  List<String> accountProfileIds = const <String>[],
}) {
  return EventProfileGroup(
    idValue: EventLinkedAccountProfileTextValue(id),
    labelValue: EventLinkedAccountProfileTextValue(label),
    orderValue: EventProfileGroupOrderValue(order),
    profiles: profiles,
    accountProfileIdValues: accountProfileIds
        .map(EventLinkedAccountProfileTextValue.new)
        .toList(),
  );
}

EventLinkedAccountProfile _buildLinkedProfile({
  required String id,
  required String displayName,
  required String profileType,
  required String slug,
}) {
  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(displayName),
    profileTypeValue: AccountProfileTypeValue(profileType),
    slugValue: SlugValue()..parse(slug),
  );
}

EventOccurrenceOption _buildOccurrence({
  required String id,
  required DateTime start,
  DateTime? end,
  bool isSelected = false,
  List<EventProgrammingItem> programmingItems = const <EventProgrammingItem>[],
  List<EventProfileGroup> profileGroups = const <EventProfileGroup>[],
  List<String> tags = const <String>[],
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
    programmingCountValue: EventProgrammingCountValue()
      ..parse(programmingItems.length.toString()),
    programmingItems: programmingItems,
    profileGroups: profileGroups,
    tags: tags.map(VenueEventTagValue.new).toList(growable: false),
  );
}

EventProgrammingItem _buildProgrammingItem({
  required String time,
  String? title,
}) {
  return EventProgrammingItem(
    timeValue: EventProgrammingTimeValue()..parse(time),
    titleValue: title == null
        ? null
        : EventLinkedAccountProfileTextValue(title),
  );
}

InviteModel _buildInviteForEvent({
  required String id,
  required String eventId,
  String occurrenceId = '507f1f77bcf86cd799439012',
}) {
  return buildInviteModelFromPrimitives(
    id: id,
    eventId: eventId,
    eventName: 'Evento $id',
    occurrenceId: occurrenceId,
    eventDateTime: DateTime(2026, 3, 15, 20),
    eventImageUrl: 'https://example.com/$id.png',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Convite $id',
    tags: const ['show'],
    inviterName: 'Convidador',
  );
}
