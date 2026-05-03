import 'dart:convert';

import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_name_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/invite_contact_region_code_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/invites_repository_contract_values.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_contract.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('previewShareCode decodes canonical preview payload', () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(
        previewResponse: {'invite': _buildInvitePayload(id: 'share:ABCD1234')},
      ),
    );

    final preview = await repository.previewShareCode(
      invitesRepoString('ABCD1234', defaultValue: '', isRequired: true),
    );

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
            'occurrence_id': 'occurrence-1',
          },
        },
      ),
    );

    await expectLater(
      repository.previewShareCode(
        invitesRepoString('BROKEN', defaultValue: '', isRequired: true),
      ),
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

    final result = await repository.acceptInvite(
      invitesRepoString('invite-1', defaultValue: '', isRequired: true),
    );

    expect(result.inviteId, 'invite-1');
    expect(result.isAccepted, isTrue);
    expect(result.nextStep, InviteNextStep.freeConfirmationCreated);
    expect(
      result.supersededInviteIds.map((inviteId) => inviteId.value).toList(),
      ['invite-2'],
    );
  });

  test('acceptInviteByCode routes to share accept endpoint', () async {
    final backend = _FakeInvitesBackend(
      acceptResponse: {
        'invite_id': 'invite-from-share',
        'status': 'accepted',
        'credited_acceptance': true,
        'attendance_policy': 'free_confirmation_only',
        'next_step': 'free_confirmation_created',
        'superseded_invite_ids': [],
        'accepted_at': null,
      },
    );
    final repository = InvitesRepository(backend: backend);

    final result = await repository.acceptInviteByCode(
      invitesRepoString('ABCD1234'),
    );

    expect(result.inviteId, 'invite-from-share');
    expect(result.isAccepted, isTrue);
    expect(backend.acceptShareCodeCalls, ['ABCD1234']);
    expect(backend.acceptInviteCalls, isEmpty);
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

    final result = await repository.materializeShareCode(
      invitesRepoString('ABCD1234', defaultValue: '', isRequired: true),
    );

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

    final result = await repository.declineInvite(
      invitesRepoString('invite-1', defaultValue: '', isRequired: true),
    );

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

  test('importContacts preserves account-profile recipient metadata', () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(
        importContactsResponse: {
          'matches': [
            {
              'contact_hash': 'hash-1',
              'type': 'phone',
              'user_id': 'user-1',
              'receiver_account_profile_id': 'profile-1',
              'display_name': 'Matched Contact',
              'avatar_url': null,
              'profile_exposure_level': 'capped_profile',
              'inviteable_reasons': ['contact_match'],
              'is_inviteable': true,
            },
          ],
        },
      ),
    );
    final contacts = InviteContacts(regionCodeValue: _regionCodeValue('BR'))
      ..add(
        buildContactModel(
          id: 'contact-1',
          displayName: 'Matched Contact',
          phones: <String>['+55 27 99999-9999'],
        ),
      );

    final matches = await repository.importContacts(contacts);

    expect(matches.single.receiverAccountProfileId, 'profile-1');
    expect(matches.single.profileExposureLevel, 'capped_profile');
    expect(matches.single.inviteableReasons, ['contact_match']);
  });

  test('fetchInviteableRecipients reads backend-computed unified list',
      () async {
    final repository = InvitesRepository(
      backend: _FakeInvitesBackend(
        inviteableContactsResponse: {
          'items': [
            {
              'user_id': 'user-1',
              'receiver_account_profile_id': 'profile-1',
              'display_name': 'Friend Contact',
              'avatar_url': null,
              'profile_exposure_level': 'full_profile',
              'contact_hash': 'hash-1',
              'contact_type': 'phone',
              'inviteable_reasons': [
                'contact_match',
                'favorite_by_you',
                'favorited_you',
                'friend',
              ],
              'is_inviteable': true,
            },
          ],
        },
      ),
    );

    final recipients = await repository.fetchInviteableRecipients();

    expect(recipients, hasLength(1));
    expect(recipients.single.receiverAccountProfileId, 'profile-1');
    expect(recipients.single.contactHash, 'hash-1');
    expect(recipients.single.contactType, 'phone');
    expect(recipients.single.isFriend, isTrue);
    expect(
      repository.inviteableRecipientsStreamValue.value?.single.userId,
      'user-1',
    );
  });

  test('importContacts sends region-aware OTP-compatible phone hash variants',
      () async {
    final backend = _FakeInvitesBackend(
      importContactsResponse: const {'matches': []},
    );
    final repository = InvitesRepository(backend: backend);
    final contacts = InviteContacts(regionCodeValue: _regionCodeValue('BR'))
      ..add(
        buildContactModel(
          id: 'contact-1',
          displayName: 'Local Contact',
          phones: <String>['(27) 99999-9999'],
        ),
      );

    await repository.importContacts(contacts);

    final payloadContacts =
        backend.importContactPayloads.single['contacts'] as List<dynamic>;
    final phoneHashes = payloadContacts
        .whereType<Map<String, dynamic>>()
        .where((item) => item['type'] == 'phone')
        .map((item) => item['hash'])
        .toList();

    expect(phoneHashes, contains(_sha256('27999999999')));
    expect(phoneHashes, contains(_sha256('5527999999999')));
  });

  test(
      'importContacts skips repeated unchanged hash import while cache is fresh',
      () async {
    final importedAt = DateTime.utc(2026, 5);
    var now = importedAt;
    final backend = _FakeInvitesBackend(
      importContactsResponse: const {'matches': []},
    );
    final cache = _FakeInviteContactImportCache();
    final repository = InvitesRepository(
      backend: backend,
      contactImportCache: cache,
      now: () => now,
      currentUserIdProvider: () async => 'viewer-1',
      tenantCacheScopeProvider: () async => 'tenant-1',
    );

    final contacts = InviteContacts(regionCodeValue: _regionCodeValue('BR'))
      ..add(
        buildContactModel(
          id: 'contact-1',
          displayName: 'Contato Cache',
          phones: <String>['+55 27 99999-9999'],
        ),
      );

    await repository.importContacts(contacts);
    now = importedAt.add(const Duration(minutes: 10));
    await repository.importContacts(contacts);

    expect(backend.importContactPayloads, hasLength(1));
    expect(cache.writeCount, 1);
  });

  test(
      'importContacts reuses repository-cached matches while signature cache is fresh',
      () async {
    final importedAt = DateTime.utc(2026, 5);
    var now = importedAt;
    final backend = _FakeInvitesBackend(
      importContactsResponse: {
        'matches': [
          {
            'contact_hash': 'hash-1',
            'type': 'phone',
            'user_id': 'user-1',
            'receiver_account_profile_id': 'profile-1',
            'display_name': 'Matched Contact',
            'avatar_url': null,
            'profile_exposure_level': 'capped_profile',
            'inviteable_reasons': ['contact_match'],
            'is_inviteable': true,
          },
        ],
      },
    );
    final cache = _FakeInviteContactImportCache();
    final repository = InvitesRepository(
      backend: backend,
      contactImportCache: cache,
      now: () => now,
      currentUserIdProvider: () async => 'viewer-1',
      tenantCacheScopeProvider: () async => 'tenant-1',
    );

    final contacts = InviteContacts(regionCodeValue: _regionCodeValue('BR'))
      ..add(
        buildContactModel(
          id: 'contact-1',
          displayName: 'Contato Cache',
          phones: <String>['+55 27 99999-9999'],
        ),
      );

    final firstMatches = await repository.importContacts(contacts);
    now = importedAt.add(const Duration(minutes: 10));
    final secondMatches = await repository.importContacts(contacts);

    expect(backend.importContactPayloads, hasLength(1));
    expect(firstMatches.single.receiverAccountProfileId, 'profile-1');
    expect(secondMatches.single.receiverAccountProfileId, 'profile-1');
    expect(
      repository.importedContactMatchesStreamValue.value?.single.displayName,
      'Matched Contact',
    );
  });

  test(
      'hydrateImportedContactMatchesFromCache restores persisted matches into a fresh repository instance',
      () async {
    final importedAt = DateTime.utc(2026, 5);
    final cache = _FakeInviteContactImportCache();
    final primingBackend = _FakeInvitesBackend(
      importContactsResponse: {
        'matches': [
          {
            'contact_hash': 'hash-1',
            'type': 'phone',
            'user_id': 'user-1',
            'receiver_account_profile_id': 'profile-1',
            'display_name': 'Matched Contact',
            'avatar_url': null,
            'profile_exposure_level': 'capped_profile',
            'inviteable_reasons': ['contact_match'],
            'is_inviteable': true,
          },
        ],
      },
    );
    final primingRepository = InvitesRepository(
      backend: primingBackend,
      contactImportCache: cache,
      now: () => importedAt,
      currentUserIdProvider: () async => 'viewer-1',
      tenantCacheScopeProvider: () async => 'tenant-1',
    );

    final contacts = InviteContacts(regionCodeValue: _regionCodeValue('BR'))
      ..add(
        buildContactModel(
          id: 'contact-1',
          displayName: 'Contato Cache',
          phones: <String>['+55 27 99999-9999'],
        ),
      );

    await primingRepository.importContacts(contacts);
    expect(primingBackend.importContactPayloads, hasLength(1));

    final coldBackend = _FakeInvitesBackend(
      importContactsResponse: const {'matches': []},
    );
    final coldRepository = InvitesRepository(
      backend: coldBackend,
      contactImportCache: cache,
      now: () => importedAt.add(const Duration(minutes: 10)),
      currentUserIdProvider: () async => 'viewer-1',
      tenantCacheScopeProvider: () async => 'tenant-1',
    );

    final hydrated =
        await coldRepository.hydrateImportedContactMatchesFromCache(contacts);

    expect(coldBackend.importContactPayloads, isEmpty);
    expect(hydrated, isNotNull);
    expect(hydrated!.single.receiverAccountProfileId, 'profile-1');
    expect(
      coldRepository
          .importedContactMatchesStreamValue.value?.single.displayName,
      'Matched Contact',
    );
  });

  test('importContacts scopes fresh import cache by tenant', () async {
    final importedAt = DateTime.utc(2026, 5);
    var tenantScope = 'tenant-1';
    final backend = _FakeInvitesBackend(
      importContactsResponse: const {'matches': []},
    );
    final cache = _FakeInviteContactImportCache();
    final repository = InvitesRepository(
      backend: backend,
      contactImportCache: cache,
      now: () => importedAt,
      currentUserIdProvider: () async => 'viewer-1',
      tenantCacheScopeProvider: () async => tenantScope,
    );
    final contacts = InviteContacts(regionCodeValue: _regionCodeValue('BR'))
      ..add(
        buildContactModel(
          id: 'contact-1',
          displayName: 'Contato Cache',
          phones: <String>['+55 27 99999-9999'],
        ),
      );

    await repository.importContacts(contacts);
    tenantScope = 'tenant-2';
    await repository.importContacts(contacts);

    expect(backend.importContactPayloads, hasLength(2));
    expect(cache.writeCount, 2);
  });

  test('importContacts reimports changed hashes and explicit refreshes',
      () async {
    final importedAt = DateTime.utc(2026, 5);
    var now = importedAt;
    final backend = _FakeInvitesBackend(
      importContactsResponse: const {'matches': []},
    );
    final cache = _FakeInviteContactImportCache();
    final repository = InvitesRepository(
      backend: backend,
      contactImportCache: cache,
      now: () => now,
      currentUserIdProvider: () async => 'viewer-1',
      tenantCacheScopeProvider: () async => 'tenant-1',
    );
    final contacts = InviteContacts(regionCodeValue: _regionCodeValue('BR'))
      ..add(
        buildContactModel(
          id: 'contact-1',
          displayName: 'Contato Cache',
          phones: <String>['+55 27 99999-9999'],
        ),
      );
    final changedContacts =
        InviteContacts(regionCodeValue: _regionCodeValue('BR'))
          ..add(
            buildContactModel(
              id: 'contact-2',
              displayName: 'Contato Novo',
              phones: <String>['+55 27 98888-7777'],
            ),
          );
    final forcedContacts = InviteContacts(
      regionCodeValue: _regionCodeValue('BR'),
      forceImportValue: DomainBooleanValue()..parse('true'),
    )..add(
        buildContactModel(
          id: 'contact-1',
          displayName: 'Contato Cache',
          phones: <String>['+55 27 99999-9999'],
        ),
      );

    await repository.importContacts(contacts);
    now = importedAt.add(const Duration(minutes: 10));
    await repository.importContacts(changedContacts);
    await repository.importContacts(forcedContacts);

    expect(backend.importContactPayloads, hasLength(3));
    expect(cache.writeCount, 3);
  });

  test('sendInvites targets receiver account profile when present', () async {
    final backend = _FakeInvitesBackend(
      sendInvitesResponse: {
        'created': [
          {
            'invite_id': 'invite-1',
            'receiver_account_profile_id': 'profile-1',
          },
        ],
        'already_invited': [],
      },
    );
    final repository = InvitesRepository(backend: backend);
    final recipients = InviteRecipients()
      ..add(
        EventFriendResume(
          idValue: UserIdValue()..parse('user-1'),
          accountProfileIdValue: InviteAccountProfileIdValue()
            ..parse('profile-1'),
          displayNameValue: UserDisplayNameValue()..parse('Friend Contact'),
          avatarUrlValue: UserAvatarValue(),
        ),
      );

    await repository.sendInvites(
      invitesRepoString('event-1', defaultValue: '', isRequired: true),
      recipients,
      occurrenceId:
          invitesRepoString('occurrence-1', defaultValue: '', isRequired: true),
    );

    expect(
      backend.sentInvitePayloads.single['recipients'],
      [
        {'receiver_account_profile_id': 'profile-1'},
      ],
    );
    expect(
      (await repository.getSentInvitesForOccurrence(
        invitesRepoString('occurrence-1', defaultValue: '', isRequired: true),
      ))
          .single
          .friend
          .accountProfileId,
      'profile-1',
    );
  });

  test('createShareCode sends and returns the selected occurrence identity',
      () async {
    final backend = _FakeInvitesBackend(
      createShareCodeResponse: {
        'code': 'SHARE-CODE',
        'target_ref': {
          'event_id': 'event-1',
          'occurrence_id': 'occurrence-2',
        },
      },
    );
    final repository = InvitesRepository(backend: backend);

    final result = await repository.createShareCode(
      eventId: invitesRepoString(
        'event-1',
        defaultValue: '',
        isRequired: true,
      ),
      occurrenceId: invitesRepoString(
        'occurrence-2',
        defaultValue: '',
        isRequired: true,
      ),
    );

    expect(result.code, 'SHARE-CODE');
    expect(result.eventId, 'event-1');
    expect(result.occurrenceId, 'occurrence-2');
    expect(backend.createdShareCodePayloads.single, {
      'target_ref': {
        'event_id': 'event-1',
        'occurrence_id': 'occurrence-2',
      },
    });
  });

  test(
      'importContacts chunks expanded payloads to backend cap and merges matches',
      () async {
    final expectedHash = _sha256('5527999990250');
    final backend = _FakeInvitesBackend(
      importContactsResponseBuilder: (payload) {
        final contacts = payload['contacts'] as List<dynamic>;
        final hasExpectedHash = contacts.whereType<Map<String, dynamic>>().any(
              (item) => item['type'] == 'phone' && item['hash'] == expectedHash,
            );
        return {
          'matches': hasExpectedHash
              ? [
                  {
                    'contact_hash': expectedHash,
                    'type': 'phone',
                    'user_id': 'user-250',
                    'receiver_account_profile_id': 'profile-250',
                    'display_name': 'Contato 250',
                    'avatar_url': null,
                    'profile_exposure_level': 'capped_profile',
                    'inviteable_reasons': ['contact_match'],
                    'is_inviteable': true,
                  },
                ]
              : [],
        };
      },
    );
    final repository = InvitesRepository(backend: backend);
    final contacts = InviteContacts(regionCodeValue: _regionCodeValue('BR'));
    for (var index = 0; index <= 250; index += 1) {
      contacts.add(
        buildContactModel(
          id: 'contact-$index',
          displayName: 'Contato $index',
          phones: <String>['(27) 99999-${index.toString().padLeft(4, '0')}'],
        ),
      );
    }

    final matches = await repository.importContacts(contacts);

    expect(backend.importContactPayloads, hasLength(2));
    expect(
      backend.importContactPayloads
          .map((payload) => (payload['contacts'] as List<dynamic>).length),
      [500, 2],
    );
    expect(matches.single.receiverAccountProfileId, 'profile-250');
  });

  test('contact group CRUD maps backend payloads', () async {
    final backend = _FakeInvitesBackend(
      contactGroupsResponse: {
        'data': [
          {
            'id': 'group-1',
            'name': 'Rolê',
            'recipient_account_profile_ids': ['profile-1'],
          },
        ],
      },
      createContactGroupResponse: {
        'data': {
          'id': 'group-2',
          'name': 'Amigos',
          'recipient_account_profile_ids': ['profile-2'],
        },
      },
      updateContactGroupResponse: {
        'data': {
          'id': 'group-2',
          'name': 'Amigos próximos',
          'recipient_account_profile_ids': ['profile-1', 'profile-2'],
        },
      },
    );
    final repository = InvitesRepository(backend: backend);

    final groups = await repository.fetchContactGroups();
    final created = await repository.createContactGroup(
      nameValue: InviteContactGroupNameValue()..parse('Amigos'),
      recipientAccountProfileIds: buildInviteAccountProfileIds(['profile-2']),
    );
    final updated = await repository.updateContactGroup(
      groupIdValue: InviteContactGroupIdValue()..parse('group-2'),
      nameValue: InviteContactGroupNameValue()..parse('Amigos próximos'),
      recipientAccountProfileIds: buildInviteAccountProfileIds(
        ['profile-1', 'profile-2'],
      ),
    );
    await repository.deleteContactGroup(
      InviteContactGroupIdValue()..parse('group-2'),
    );

    expect(groups.single.name, 'Rolê');
    expect(groups.single.recipientAccountProfileIds, ['profile-1']);
    expect(created?.id, 'group-2');
    expect(updated?.name, 'Amigos próximos');
    expect(backend.createdContactGroupPayloads.single, {
      'name': 'Amigos',
      'recipient_account_profile_ids': ['profile-2'],
    });
    expect(backend.updatedContactGroupPayloads.single, {
      'group_id': 'group-2',
      'name': 'Amigos próximos',
      'recipient_account_profile_ids': ['profile-1', 'profile-2'],
    });
    expect(backend.deletedContactGroupIds, ['group-2']);
  });
}

class _FakeInviteContactImportCache
    implements InviteContactImportCacheContract {
  final entries = <String, InviteContactImportCacheEntry>{};
  int readCount = 0;
  int writeCount = 0;

  @override
  Future<InviteContactImportCacheEntry?> read(String cacheKey) async {
    readCount += 1;
    return entries[cacheKey];
  }

  @override
  Future<void> write(
    String cacheKey,
    InviteContactImportCacheEntry entry,
  ) async {
    writeCount += 1;
    entries[cacheKey] = entry;
  }
}

class _FakeInvitesBackend implements InvitesBackendContract {
  _FakeInvitesBackend({
    Map<String, dynamic>? fetchInvitesResponse,
    Map<String, dynamic>? previewResponse,
    Map<String, dynamic>? materializeResponse,
    Map<String, dynamic>? acceptResponse,
    Map<String, dynamic>? declineResponse,
    Map<String, dynamic>? importContactsResponse,
    Map<String, dynamic>? inviteableContactsResponse,
    Map<String, dynamic>? contactGroupsResponse,
    Map<String, dynamic>? createContactGroupResponse,
    Map<String, dynamic>? updateContactGroupResponse,
    Map<String, dynamic>? sendInvitesResponse,
    Map<String, dynamic>? createShareCodeResponse,
    Map<String, dynamic> Function(Map<String, dynamic> payload)?
        importContactsResponseBuilder,
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
            },
        _importContactsResponse =
            importContactsResponse ?? const {'matches': []},
        _inviteableContactsResponse =
            inviteableContactsResponse ?? const {'items': []},
        _contactGroupsResponse = contactGroupsResponse ?? const {'data': []},
        _createContactGroupResponse = createContactGroupResponse ??
            const {
              'data': {
                'id': 'group-1',
                'name': 'Grupo',
                'recipient_account_profile_ids': [],
              },
            },
        _updateContactGroupResponse = updateContactGroupResponse ??
            const {
              'data': {
                'id': 'group-1',
                'name': 'Grupo',
                'recipient_account_profile_ids': [],
              },
            },
        _sendInvitesResponse = sendInvitesResponse ??
            const {
              'created': [],
              'already_invited': [],
            },
        _createShareCodeResponse = createShareCodeResponse ??
            const {
              'code': 'SHARE-CODE',
              'target_ref': {
                'event_id': 'event-1',
                'occurrence_id': 'occurrence-1',
              },
            },
        _importContactsResponseBuilder = importContactsResponseBuilder;

  final Map<String, dynamic> _fetchInvitesResponse;
  final Map<String, dynamic> _previewResponse;
  final Map<String, dynamic> _materializeResponse;
  final Map<String, dynamic> _acceptResponse;
  final Map<String, dynamic> _declineResponse;
  final Map<String, dynamic> _importContactsResponse;
  final Map<String, dynamic> _inviteableContactsResponse;
  final Map<String, dynamic> _contactGroupsResponse;
  final Map<String, dynamic> _createContactGroupResponse;
  final Map<String, dynamic> _updateContactGroupResponse;
  final Map<String, dynamic> _sendInvitesResponse;
  final Map<String, dynamic> _createShareCodeResponse;
  final Map<String, dynamic> Function(Map<String, dynamic> payload)?
      _importContactsResponseBuilder;

  int fetchInvitesCalls = 0;
  final List<String> acceptInviteCalls = <String>[];
  final List<String> acceptShareCodeCalls = <String>[];
  final List<Map<String, dynamic>> sentInvitePayloads =
      <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> createdShareCodePayloads =
      <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> importContactPayloads =
      <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> createdContactGroupPayloads =
      <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> updatedContactGroupPayloads =
      <Map<String, dynamic>>[];
  final List<String> deletedContactGroupIds = <String>[];

  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId) async {
    acceptInviteCalls.add(inviteId);
    return _acceptResponse;
  }

  @override
  Future<Map<String, dynamic>> acceptShareCode(String code) async {
    acceptShareCodeCalls.add(code);
    return _acceptResponse;
  }

  @override
  Future<Map<String, dynamic>> createShareCode(
    InviteShareCodeCreateRequest request,
  ) async {
    final payload = request.toJson();
    createdShareCodePayloads.add(payload);
    return _createShareCodeResponse;
  }

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
    InviteContactImportRequest request,
  ) async {
    final payload = request.toJson();
    importContactPayloads.add(payload);
    final builder = _importContactsResponseBuilder;
    if (builder != null) {
      return builder(payload);
    }
    return _importContactsResponse;
  }

  @override
  Future<Map<String, dynamic>> fetchInviteableContacts() async =>
      _inviteableContactsResponse;

  @override
  Future<Map<String, dynamic>> fetchContactGroups() async =>
      _contactGroupsResponse;

  @override
  Future<Map<String, dynamic>> createContactGroup({
    required String name,
    required List<String> recipientAccountProfileIds,
  }) async {
    final payload = {
      'name': name,
      'recipient_account_profile_ids': recipientAccountProfileIds,
    };
    createdContactGroupPayloads.add(payload);
    return _createContactGroupResponse;
  }

  @override
  Future<Map<String, dynamic>> updateContactGroup({
    required String groupId,
    String? name,
    List<String>? recipientAccountProfileIds,
  }) async {
    updatedContactGroupPayloads.add({
      'group_id': groupId,
      if (name != null) 'name': name,
      if (recipientAccountProfileIds != null)
        'recipient_account_profile_ids': recipientAccountProfileIds,
    });
    return _updateContactGroupResponse;
  }

  @override
  Future<Map<String, dynamic>> deleteContactGroup(String groupId) async {
    deletedContactGroupIds.add(groupId);
    return const <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> materializeShareCode(String code) async =>
      _materializeResponse;

  @override
  Future<Map<String, dynamic>> sendInvites(
    InviteSendRequest request,
  ) async {
    final payload = request.toJson();
    sentInvitePayloads.add(payload);
    return _sendInvitesResponse;
  }
}

String _sha256(String raw) => sha256.convert(utf8.encode(raw)).toString();

InviteContactRegionCodeValue _regionCodeValue(String raw) =>
    InviteContactRegionCodeValue()..parse(raw);

Map<String, dynamic> _buildInvitePayload({
  required String id,
  String eventId = 'event-1',
  String occurrenceId = 'occurrence-1',
  String message = 'Bora?',
}) {
  return {
    'id': id,
    'event_id': eventId,
    'occurrence_id': occurrenceId,
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
