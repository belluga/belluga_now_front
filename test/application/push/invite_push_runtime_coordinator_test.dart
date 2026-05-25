import 'dart:async';

import 'package:belluga_now/application/push/invite_push_runtime_coordinator.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'refreshes pending invites on passive invite push without embedded invite',
      () async {
    final invitesRepository = _FakeInvitesRepository();
    final coordinator = InvitePushRuntimeCoordinator(
      invitesRepository: invitesRepository,
      navigatePath: (_) async {},
    );

    await coordinator.handleIncomingMessage(
      _buildRemoteMessage(
        data: <String, dynamic>{
          'push_type': 'invite_received',
          'invite_id': '507f1f77bcf86cd799439011',
        },
      ),
    );

    expect(invitesRepository.refreshPendingInvitesCalls, 1);
  });

  test('opens invite flow when tapped invite is still pending', () async {
    final invitesRepository = _FakeInvitesRepository(
      pendingInvites: <InviteModel>[
        buildInviteModelFromPrimitives(
          id: '507f1f77bcf86cd799439011',
          eventId: '507f1f77bcf86cd799439012',
          eventName: 'Evento',
          eventDateTime: DateTime(2026, 5, 20, 20),
          eventImageUrl: 'https://example.com/event.jpg',
          location: 'Guarapari',
          hostName: 'Belluga',
          message: 'Teste',
          tags: const <String>['show'],
          occurrenceId: '507f1f77bcf86cd799439013',
          inviterName: 'Sender User',
        ),
      ],
    );
    final navigatedPaths = <String>[];
    final coordinator = InvitePushRuntimeCoordinator(
      invitesRepository: invitesRepository,
      navigatePath: (path) async => navigatedPaths.add(path),
      currentPathProvider: () => '/agenda',
    );

    await coordinator.handleNotificationTap(
      _buildRemoteMessage(
        data: <String, dynamic>{
          'push_type': 'invite_received',
          'invite_id': '507f1f77bcf86cd799439011',
          'event_id': '507f1f77bcf86cd799439012',
          'occurrence_id': '507f1f77bcf86cd799439013',
          'push_message_id': 'push-1',
          'message_instance_id': 'instance-1',
        },
      ),
    );

    expect(invitesRepository.refreshPendingInvitesCalls, 1);
    expect(
      navigatedPaths,
      <String>[
        '/convites?invite=507f1f77bcf86cd799439011&fallback=%2Fagenda%2Fevento%2F507f1f77bcf86cd799439012%3Foccurrence%3D507f1f77bcf86cd799439013',
      ],
    );
  });

  test('includes explicit event fallback when invite is no longer renderable',
      () async {
    final navigatedPaths = <String>[];
    final coordinator = InvitePushRuntimeCoordinator(
      invitesRepository: _FakeInvitesRepository(),
      navigatePath: (path) async => navigatedPaths.add(path),
      currentPathProvider: () => '/agenda',
    );

    await coordinator.handleNotificationTap(
      _buildRemoteMessage(
        data: <String, dynamic>{
          'push_type': 'invite_received',
          'invite_id': '507f1f77bcf86cd799439011',
          'event_id': '507f1f77bcf86cd799439012',
          'occurrence_id': '507f1f77bcf86cd799439013',
          'push_message_id': 'push-2',
          'message_instance_id': 'instance-2',
        },
      ),
    );

    expect(
      navigatedPaths,
      <String>[
        '/convites?invite=507f1f77bcf86cd799439011&fallback=%2Fagenda%2Fevento%2F507f1f77bcf86cd799439012%3Foccurrence%3D507f1f77bcf86cd799439013',
      ],
    );
  });

  test('navigates immediately on tap without waiting for invite refresh',
      () async {
    final refreshCompleter = Completer<void>();
    final invitesRepository = _FakeInvitesRepository(
      refreshPendingInvitesCompleter: refreshCompleter,
    );
    final navigatedPaths = <String>[];
    final coordinator = InvitePushRuntimeCoordinator(
      invitesRepository: invitesRepository,
      navigatePath: (path) async => navigatedPaths.add(path),
      currentPathProvider: () => '/agenda',
    );

    await coordinator.handleNotificationTap(
      _buildRemoteMessage(
        data: <String, dynamic>{
          'push_type': 'invite_received',
          'invite_id': '507f1f77bcf86cd799439011',
          'event_id': '507f1f77bcf86cd799439012',
          'occurrence_id': '507f1f77bcf86cd799439013',
          'push_message_id': 'push-4',
          'message_instance_id': 'instance-4',
        },
      ),
    );

    expect(invitesRepository.refreshPendingInvitesCalls, 1);
    expect(
      navigatedPaths,
      <String>[
        '/convites?invite=507f1f77bcf86cd799439011&fallback=%2Fagenda%2Fevento%2F507f1f77bcf86cd799439012%3Foccurrence%3D507f1f77bcf86cd799439013',
      ],
    );

    refreshCompleter.complete();
    await Future<void>.delayed(Duration.zero);
  });

  test('falls back to home when no invite or event context is available',
      () async {
    final navigatedPaths = <String>[];
    final coordinator = InvitePushRuntimeCoordinator(
      invitesRepository: _FakeInvitesRepository(),
      navigatePath: (path) async => navigatedPaths.add(path),
      currentPathProvider: () => '/agenda',
    );

    await coordinator.handleNotificationTap(
      _buildRemoteMessage(
        data: <String, dynamic>{
          'push_type': 'invite_received',
          'push_message_id': 'push-3',
          'message_instance_id': 'instance-3',
        },
      ),
    );

    expect(navigatedPaths, <String>['/']);
  });

  test('invite accepted push refreshes the affected sent invite occurrence',
      () async {
    final invitesRepository = _FakeInvitesRepository();
    final coordinator = InvitePushRuntimeCoordinator(
      invitesRepository: invitesRepository,
      navigatePath: (_) async {},
    );

    await coordinator.handleIncomingMessage(
      _buildRemoteMessage(
        data: <String, dynamic>{
          'push_type': 'invite_accepted',
          'invite_id': '507f1f77bcf86cd799439011',
          'event_id': '507f1f77bcf86cd799439012',
          'occurrence_id': '507f1f77bcf86cd799439013',
          'accepted_by_account_profile_id': '507f1f77bcf86cd799439014',
        },
      ),
    );

    expect(invitesRepository.refreshPendingInvitesCalls, 0);
    expect(invitesRepository.sentStatusRefreshes, [
      {
        'occurrence_id': '507f1f77bcf86cd799439013',
        'event_id': '507f1f77bcf86cd799439012',
        'recipient_account_profile_ids': ['507f1f77bcf86cd799439014'],
      },
    ]);
    expect(invitesRepository.sentSummaryRefreshes, [
      {
        'occurrence_id': '507f1f77bcf86cd799439013',
        'event_id': '507f1f77bcf86cd799439012',
        'preview_limit': null,
      },
    ]);
  });

  test('invite accepted tap opens event destination and refreshes sent status',
      () async {
    final invitesRepository = _FakeInvitesRepository();
    final navigatedPaths = <String>[];
    final coordinator = InvitePushRuntimeCoordinator(
      invitesRepository: invitesRepository,
      navigatePath: (path) async => navigatedPaths.add(path),
      currentPathProvider: () => '/agenda',
    );

    await coordinator.handleNotificationTap(
      _buildRemoteMessage(
        data: <String, dynamic>{
          'push_type': 'invite_accepted',
          'invite_id': '507f1f77bcf86cd799439011',
          'event_id': '507f1f77bcf86cd799439012',
          'occurrence_id': '507f1f77bcf86cd799439013',
          'accepted_by_account_profile_id': '507f1f77bcf86cd799439014',
          'push_message_id': 'push-accepted',
          'message_instance_id': 'instance-accepted',
        },
      ),
    );

    expect(navigatedPaths, <String>[
      '/agenda/evento/507f1f77bcf86cd799439012?occurrence=507f1f77bcf86cd799439013',
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(invitesRepository.sentStatusRefreshes, [
      {
        'occurrence_id': '507f1f77bcf86cd799439013',
        'event_id': '507f1f77bcf86cd799439012',
        'recipient_account_profile_ids': ['507f1f77bcf86cd799439014'],
      },
    ]);
    expect(invitesRepository.sentSummaryRefreshes, [
      {
        'occurrence_id': '507f1f77bcf86cd799439013',
        'event_id': '507f1f77bcf86cd799439012',
        'preview_limit': null,
      },
    ]);
  });
}

RemoteMessage _buildRemoteMessage({
  required Map<String, dynamic> data,
}) {
  return RemoteMessage.fromMap(<String, dynamic>{
    'messageId': data['message_instance_id'] ?? 'message-id',
    'data': data,
  });
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository({
    List<InviteModel> pendingInvites = const <InviteModel>[],
    this.refreshPendingInvitesCompleter,
  }) {
    pendingInvitesStreamValue.addValue(pendingInvites);
  }

  final Completer<void>? refreshPendingInvitesCompleter;
  int refreshPendingInvitesCalls = 0;
  final sentStatusRefreshes = <Map<String, Object?>>[];
  final sentSummaryRefreshes = <Map<String, Object?>>[];

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async =>
      pendingInvitesStreamValue.value;

  @override
  Future<void> refreshPendingInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    refreshPendingInvitesCalls += 1;
    await refreshPendingInvitesCompleter?.future;
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      throw UnimplementedError();

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async =>
      throw UnimplementedError();

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async =>
      throw UnimplementedError();

  @override
  Future<InviteMaterializeResult> materializeShareCode(
    InvitesRepositoryContractPrimString code,
  ) async =>
      throw UnimplementedError();

  @override
  Future<InviteModel?> previewShareCode(
    InvitesRepositoryContractPrimString code,
  ) async =>
      null;

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async =>
      const <InviteContactMatch>[];

  @override
  Future<List<InviteContactGroup>> fetchContactGroups() async =>
      const <InviteContactGroup>[];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString occurrenceId,
  ) async =>
      const <SentInviteStatus>[];

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
      'recipient_account_profile_ids': recipientAccountProfileIds
          .map((recipientId) => recipientId.value)
          .toList(growable: false),
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
}
