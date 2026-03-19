import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('previewShareCode decodes canonical preview payload', () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(
        previewResponse: {'invite': _buildInvitePayload(id: 'share:ABCD1234')},
      ),
    );

    final preview = await repository.previewShareCode('ABCD1234');

    expect(preview, isNotNull);
    expect(preview!.id, 'share:ABCD1234');
    expect(preview.eventId, 'event-1');
    expect(preview.primaryInviteId, 'share:ABCD1234');
  });

  test('previewShareCode fails loudly on malformed preview payload', () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(
        previewResponse: {
          'invite': {
            'id': 'share:broken',
            'event_id': 'event-1',
          },
        },
      ),
    );

    await expectLater(
      repository.previewShareCode('BROKEN'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('missing event_name'),
        ),
      ),
    );
  });

  test('acceptInvite maps canonical superseded ids and ignores legacy field',
      () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(
        acceptResponse: {
          'invite_id': 'invite-1',
          'status': 'accepted',
          'credited_acceptance': true,
          'attendance_policy': 'free_confirmation_only',
          'next_step': 'free_confirmation_created',
          'superseded_invite_ids': ['invite-2'],
          'closed_duplicate_invite_ids': ['legacy-only'],
          'accepted_at': '2099-01-01T20:00:00Z',
        },
      ),
    );

    final result = await repository.acceptInvite('invite-1');

    expect(result.inviteId, 'invite-1');
    expect(result.isAccepted, isTrue);
    expect(result.nextStep, InviteNextStep.freeConfirmationCreated);
    expect(result.supersededInviteIds, ['invite-2']);
  });

  test('materializeShareCode maps pending state from canonical payload',
      () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(
        materializeResponse: {
          'invite_id': 'invite-1',
          'status': 'pending',
          'credited_acceptance': false,
          'attendance_policy': 'free_confirmation_only',
          'accepted_at': null,
        },
      ),
    );

    final result = await repository.materializeShareCode('ABCD1234');

    expect(result.inviteId, 'invite-1');
    expect(result.isPending, isTrue);
    expect(result.creditedAcceptance, isFalse);
  });

  test('declineInvite maps canonical payload and refreshes pending invites',
      () async {
    final backend = _FakeInvitesBackend(
      declineResponse: {
        'invite_id': 'invite-1',
        'status': 'declined',
        'group_has_other_pending': true,
        'declined_at': '2099-01-01T20:00:00Z',
      },
    );
    final repository = InvitesRepository(backend: backend);

    final result = await repository.declineInvite('invite-1');

    expect(result.inviteId, 'invite-1');
    expect(result.isDeclined, isTrue);
    expect(result.groupHasOtherPending, isTrue);
    expect(backend.fetchInvitesCalls, 1);
  });

  test('fetchInvites accepts invite feed entries without custom message',
      () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(
        fetchInvitesResponse: {
          'invites': [
            _buildInvitePayload(
              id: 'invite-1',
              message: '',
            ),
          ],
        },
      ),
    );

    final invites = await repository.fetchInvites();

    expect(invites, hasLength(1));
    expect(invites.single.message, isEmpty);
  });
}

class _FakeInvitesBackend implements InvitesBackendContract {
  _FakeInvitesBackend({
    Map<String, dynamic>? fetchInvitesResponse,
    Map<String, dynamic>? previewResponse,
    Map<String, dynamic>? materializeResponse,
    Map<String, dynamic>? acceptResponse,
    Map<String, dynamic>? declineResponse,
  })  : _fetchInvitesResponse = fetchInvitesResponse ?? const {'invites': []},
        _previewResponse = previewResponse ?? const {'invite': null},
        _materializeResponse = materializeResponse ??
            const {
              'invite_id': 'invite-1',
              'status': 'pending',
              'credited_acceptance': false,
              'attendance_policy': 'free_confirmation_only',
              'accepted_at': null,
            },
        _acceptResponse = acceptResponse ??
            const {
              'invite_id': 'invite-1',
              'status': 'accepted',
              'credited_acceptance': true,
              'attendance_policy': 'free_confirmation_only',
              'next_step': 'free_confirmation_created',
              'superseded_invite_ids': [],
              'accepted_at': null,
            },
        _declineResponse = declineResponse ??
            const {
              'invite_id': 'invite-1',
              'status': 'declined',
              'group_has_other_pending': false,
              'declined_at': null,
            };

  final Map<String, dynamic> _fetchInvitesResponse;
  final Map<String, dynamic> _previewResponse;
  final Map<String, dynamic> _materializeResponse;
  final Map<String, dynamic> _acceptResponse;
  final Map<String, dynamic> _declineResponse;

  int fetchInvitesCalls = 0;

  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId) async =>
      _acceptResponse;

  @override
  Future<Map<String, dynamic>> createShareCode(
    Map<String, dynamic> payload,
  ) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> declineInvite(String inviteId) async =>
      _declineResponse;

  @override
  Future<Map<String, dynamic>> fetchInvites({
    required int page,
    required int pageSize,
  }) async {
    fetchInvitesCalls += 1;
    return _fetchInvitesResponse;
  }

  @override
  Future<Map<String, dynamic>> fetchSettings() async => const {
        'tenant_id': null,
        'limits': <String, int>{},
        'cooldowns': <String, int>{},
      };

  @override
  Future<Map<String, dynamic>> fetchShareCodePreview(String code) async =>
      _previewResponse;

  @override
  Future<Map<String, dynamic>> importContacts(
    Map<String, dynamic> payload,
  ) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> materializeShareCode(String code) async =>
      _materializeResponse;

  @override
  Future<Map<String, dynamic>> sendInvites(
    Map<String, dynamic> payload,
  ) async =>
      throw UnimplementedError();
}

Map<String, dynamic> _buildInvitePayload({
  required String id,
  String eventId = 'event-1',
  String message = 'Bora?',
}) {
  return {
    'id': id,
    'event_id': eventId,
    'event_name': 'Invite Event',
    'event_date': '2099-01-01T20:00:00Z',
    'event_image_url': 'https://example.com/event.png',
    'location': 'Guarapari',
    'host_name': 'Belluga',
    'message': message,
    'tags': ['music'],
    'attendance_policy': 'free_confirmation_only',
    'inviter_candidates': [
      {
        'invite_id': id,
        'display_name': 'Invite Sender',
        'avatar_url': 'https://example.com/avatar.png',
        'status': 'pending',
        'principal_kind': 'user',
        'principal_id': 'user-1',
      }
    ],
    'inviter_principal': {
      'kind': 'user',
      'id': 'user-1',
    },
  };
}
