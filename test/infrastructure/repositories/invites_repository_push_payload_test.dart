import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:flutter_test/flutter_test.dart';

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

class _FakeInvitesBackend implements InvitesBackendContract {
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
  Future<Map<String, dynamic>> sendInvites(
          Map<String, dynamic> payload) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> createShareCode(
          Map<String, dynamic> payload) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> acceptShareCode(String code) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> importContacts(
          Map<String, dynamic> payload) async =>
      throw UnimplementedError();
}
