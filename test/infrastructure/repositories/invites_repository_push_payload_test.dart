import 'package:belluga_now/infrastructure/dal/dao/invites/invite_sent_statuses_request.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_realtime_delta_dto.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('applyInvitePushPayload upserts invite to the top', () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(),
    );
    final baseline = await repository.fetchInvites();
    repository.pendingInvitesStreamValue.addValue(baseline);

    final payload = {
      'invites': [
        {
          'id': 'invite-push-1',
          'event_id': 'event-123',
          'occurrence_id': 'occurrence-123',
          'event_name': 'Evento Destaque',
          'event_date': DateTime.now().toIso8601String(),
          'event_image_url': 'https://example.com/event.png',
          'location': 'Centro',
          'host_name': 'Host',
          'message': 'Bora nessa?',
          'tags': ['music'],
          'inviter_name': 'Ana',
          'inviter_avatar_url': 'https://example.com/avatar.png',
          'additional_inviters': ['Bia'],
        }
      ],
    };

    repository.applyInvitePushPayload(payload);

    final updated = repository.pendingInvitesStreamValue.value;
    expect(updated.first.id, 'invite-push-1');
    expect(updated.length, baseline.length + 1);
  });

  test('applyInvitePushPayload marks matching sent invite accepted', () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(),
      now: () => DateTime.utc(2026, 5, 23, 14, 0),
    );
    repository.sentInvitesByOccurrenceStreamValue.addValue({
      invitesRepoString('occurrence-123', defaultValue: '', isRequired: true): [
        SentInviteStatus(
          friend: _friend(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Pessoa',
          ),
          status: InviteStatus.pending,
          sentAtValue: DateTimeValue()..parse('2026-05-23T13:00:00.000Z'),
        ),
      ],
    });

    repository.applyInvitePushPayload({
      'push_type': 'invite_accepted',
      'occurrence_id': 'occurrence-123',
      'event_id': 'event-123',
      'accepted_by_user_id': 'other-user-id',
      'accepted_by_account_profile_id': 'profile-1',
      'accepted_by_display_name': 'Pessoa Aceitou',
      'accepted_by_avatar_url': 'https://example.com/avatar.png',
    });
    repository.applyInvitePushPayload({
      'push_type': 'invite_accepted',
      'occurrence_id': 'occurrence-123',
      'event_id': 'event-123',
      'accepted_by_user_id': 'other-user-id',
      'accepted_by_account_profile_id': 'profile-1',
    });

    final statuses = await repository.getSentInvitesForOccurrence(
      invitesRepoString('occurrence-123', defaultValue: '', isRequired: true),
    );

    expect(statuses, hasLength(1));
    expect(statuses.single.friend.accountProfileId, 'profile-1');
    expect(statuses.single.status, InviteStatus.accepted);
    expect(
        statuses.single.sentAt.toIso8601String(), '2026-05-23T13:00:00.000Z');
    expect(
      statuses.single.respondedAt?.toIso8601String(),
      '2026-05-23T14:00:00.000Z',
    );
  });

  test(
      'applyInvitePushPayload ignores accepted push without account profile match',
      () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(),
      now: () => DateTime.utc(2026, 5, 23, 14, 0),
    );
    repository.sentInvitesByOccurrenceStreamValue.addValue({
      invitesRepoString('occurrence-123', defaultValue: '', isRequired: true): [
        SentInviteStatus(
          friend: _friend(
            userId: 'legacy-user-id',
            accountProfileId: 'profile-1',
            displayName: 'Pessoa',
          ),
          status: InviteStatus.pending,
          sentAtValue: DateTimeValue()..parse('2026-05-23T13:00:00.000Z'),
        ),
      ],
    });

    repository.applyInvitePushPayload({
      'push_type': 'invite_accepted',
      'occurrence_id': 'occurrence-123',
      'event_id': 'event-123',
      'accepted_by_user_id': 'legacy-user-id',
      'accepted_by_display_name': 'Pessoa Aceitou',
    });

    final statuses = await repository.getSentInvitesForOccurrence(
      invitesRepoString('occurrence-123', defaultValue: '', isRequired: true),
    );

    expect(statuses, hasLength(1));
    expect(statuses.single.friend.id, 'legacy-user-id');
    expect(statuses.single.friend.accountProfileId, 'profile-1');
    expect(statuses.single.status, InviteStatus.pending);
    expect(statuses.single.respondedAt, isNull);
    expect(
      statuses.single.sentAt.toIso8601String(),
      '2026-05-23T13:00:00.000Z',
    );
  });

  test('applyInvitePushPayload upserts accepted status before list hydration',
      () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(),
      now: () => DateTime.utc(2026, 5, 23, 14, 0),
    );

    repository.applyInvitePushPayload({
      'push_type': 'invite_accepted',
      'occurrence_id': 'occurrence-123',
      'event_id': 'event-123',
      'accepted_by_user_id': 'user-1',
      'accepted_by_account_profile_id': 'profile-1',
      'accepted_by_display_name': 'Pessoa Aceitou',
      'accepted_by_avatar_url': 'https://example.com/avatar.png',
    });

    final statuses = await repository.getSentInvitesForOccurrence(
      invitesRepoString('occurrence-123', defaultValue: '', isRequired: true),
    );

    expect(statuses, hasLength(1));
    expect(statuses.single.friend.id, 'user-1');
    expect(statuses.single.friend.accountProfileId, 'profile-1');
    expect(statuses.single.friend.displayName, 'Pessoa Aceitou');
    expect(statuses.single.status, InviteStatus.accepted);
  });
}

EventFriendResume _friend({
  required String userId,
  required String accountProfileId,
  required String displayName,
}) {
  return EventFriendResume(
    idValue: UserIdValue()..parse(userId),
    accountProfileIdValue: InviteAccountProfileIdValue()
      ..parse(accountProfileId),
    displayNameValue: UserDisplayNameValue()..parse(displayName),
    avatarUrlValue: UserAvatarValue(),
  );
}

class _FakeInvitesBackend implements InvitesBackendContract {
  @override
  Stream<InviteRealtimeDeltaDto> watchInvitesStream({
    String? lastEventId,
  }) =>
      const Stream<InviteRealtimeDeltaDto>.empty();

  @override
  Future<Map<String, dynamic>> fetchInvites({
    required int page,
    required int pageSize,
  }) async =>
      const {'invites': <Map<String, dynamic>>[]};

  @override
  Future<Map<String, dynamic>> fetchSettings() async => const {
        'tenant_id': null,
        'limits': <String, int>{},
        'cooldowns': <String, int>{},
      };

  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> declineInvite(String inviteId) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> sendInvites(InviteSendRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchSentInviteStatuses(
          InviteSentStatusesRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> createShareCode(
          InviteShareCodeCreateRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchShareCodePreview(String code) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> acceptShareCode(String code) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> materializeShareCode(String code) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> importContacts(
          InviteContactImportRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchInviteableContacts() async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchContactGroups() async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> createContactGroup({
    required String name,
    required List<String> recipientAccountProfileIds,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> updateContactGroup({
    required String groupId,
    String? name,
    List<String>? recipientAccountProfileIds,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> deleteContactGroup(String groupId) async =>
      throw UnimplementedError();
}
