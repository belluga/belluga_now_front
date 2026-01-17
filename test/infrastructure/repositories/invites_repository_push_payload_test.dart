import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/repositories/friends_repository_contract.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('applyInvitePushPayload upserts invite to the top', () async {
    final repository = InvitesRepository(
      friendsRepository: _FakeFriendsRepository(),
    );
    final baseline = await repository.fetchInvites();
    repository.pendingInvitesStreamValue.addValue(baseline);

    final payload = {
      'invites': [
        {
          'id': 'invite-push-1',
          'event_id': 'event-123',
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
}

class _FakeFriendsRepository extends FriendsRepositoryContract {
  @override
  final friendsStreamValue =
      StreamValue<List<InviteFriendResume>>(defaultValue: const []);

  @override
  Future<void> fetchAndCacheFriends({bool forceRefresh = false}) async {}

  @override
  Future<List<Friend>> fetchFriends() async => const [];
}
