import 'dart:async';

import 'package:belluga_now/infrastructure/repositories/inviteables_repository.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fetchInviteableRecipients decodes root items and stores cache',
      () async {
    final backend = _FakeInvitesBackend(
      response: {
        'items': [
          _inviteablePayload(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana',
          ),
        ],
      },
    );
    final repository = InviteablesRepository(backend: backend);

    final recipients = await repository.fetchInviteableRecipients();

    expect(backend.fetchInviteableContactsCalls, 1);
    expect(backend.lastRequest?.page, 1);
    expect(
      backend.lastRequest?.pageSize,
      InviteablesRepository.routeCriticalPageSize,
    );
    expect(recipients.single.receiverAccountProfileId, 'profile-1');
    expect(repository.inviteableRecipientsStreamValue.value, recipients);
  });

  test('fetchInviteableRecipients decodes data.items envelope', () async {
    final backend = _FakeInvitesBackend(
      response: {
        'data': {
          'items': [
            _inviteablePayload(
              userId: 'user-2',
              accountProfileId: 'profile-2',
              displayName: 'Bia',
            ),
          ],
        },
      },
    );
    final repository = InviteablesRepository(backend: backend);

    final recipients = await repository.fetchInviteableRecipients();

    expect(recipients.single.userId, 'user-2');
    expect(repository.inviteableRecipientsStreamValue.value, recipients);
  });

  test(
    'fetchInviteableRecipients preserves recipients when nested sent status is malformed',
    () async {
      final backend = _FakeInvitesBackend(
        response: {
          'items': [
            {
              ..._inviteablePayload(
                userId: 'user-bad',
                accountProfileId: 'profile-bad',
                displayName: 'Quebrado',
              ),
              'sent_invite_status': {
                'receiver_account_profile_id': 'profile-bad',
                'receiver_user_id': 'user-bad',
                'display_name': 'Quebrado',
                'sent_at': 'invalid-date',
              },
            },
            _inviteablePayload(
              userId: 'user-4',
              accountProfileId: 'profile-4',
              displayName: 'Dora',
            ),
          ],
        },
      );
      final repository = InviteablesRepository(backend: backend);

      final recipients = await repository.fetchInviteableRecipients();

      expect(recipients, hasLength(2));
      final malformedRecipient = recipients.firstWhere(
        (recipient) => recipient.receiverAccountProfileId == 'profile-bad',
      );
      expect(malformedRecipient.sentInviteStatus, isNull);
      expect(
        recipients.any(
          (recipient) => recipient.receiverAccountProfileId == 'profile-4',
        ),
        isTrue,
      );
      expect(repository.inviteableRecipientsStreamValue.value, recipients);
    },
  );

  test(
    'fetchInviteableRecipients keeps valid recipients when one top-level payload is malformed',
    () async {
      final backend = _FakeInvitesBackend(
        response: {
          'items': [
            {
              ..._inviteablePayload(
                userId: 'user-bad',
                accountProfileId: 'profile-bad',
                displayName: 'A',
              ),
            },
            _inviteablePayload(
              userId: 'user-5',
              accountProfileId: 'profile-5',
              displayName: 'Elisa',
            ),
          ],
        },
      );
      final repository = InviteablesRepository(backend: backend);

      final recipients = await repository.fetchInviteableRecipients();

      expect(recipients, hasLength(1));
      expect(recipients.single.receiverAccountProfileId, 'profile-5');
      expect(repository.inviteableRecipientsStreamValue.value, recipients);
    },
  );

  test('fetchInviteableRecipients dedupes concurrent refreshes', () async {
    final gate = Completer<void>();
    final backend = _FakeInvitesBackend(
      response: {
        'items': [
          _inviteablePayload(
            userId: 'user-3',
            accountProfileId: 'profile-3',
            displayName: 'Caio',
          ),
        ],
      },
      gate: gate,
    );
    final repository = InviteablesRepository(backend: backend);

    final first = repository.fetchInviteableRecipients();
    final second = repository.fetchInviteableRecipients();
    expect(identical(first, second), isTrue);

    gate.complete();
    await Future.wait([first, second]);

    expect(backend.fetchInviteableContactsCalls, 1);
    await repository.fetchInviteableRecipients();
    expect(backend.fetchInviteableContactsCalls, 2);
  });
}

Map<String, Object?> _inviteablePayload({
  required String userId,
  required String accountProfileId,
  required String displayName,
}) =>
    {
      'user_id': userId,
      'receiver_account_profile_id': accountProfileId,
      'display_name': displayName,
      'avatar_url': null,
      'profile_exposure_level': 'full_profile',
      'inviteable_reasons': ['contact_match'],
      'is_inviteable': true,
    };

class _FakeInvitesBackend implements InvitesBackendContract {
  _FakeInvitesBackend({
    required this.response,
    this.gate,
  });

  final Map<String, dynamic> response;
  final Completer<void>? gate;
  int fetchInviteableContactsCalls = 0;
  InviteableContactsRequest? lastRequest;

  @override
  Future<Map<String, dynamic>> fetchInviteableContacts(
    InviteableContactsRequest request,
  ) async {
    fetchInviteableContactsCalls += 1;
    lastRequest = request;
    await gate?.future;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
