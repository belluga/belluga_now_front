import 'dart:async';

import 'package:belluga_now/application/invites/invite_contact_import_hashes.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/inviteable_reasons.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_hash_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_type_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_profile_exposure_level_value.dart';
import 'package:belluga_now/domain/invites/value_objects/inviteable_reason_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/inviteables_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
import 'package:belluga_now/domain/schedule/value_objects/sent_invite_summary_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_external_contact_share_target.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class _FakeContactsRepository implements ContactsRepositoryContract {
  _FakeContactsRepository({
    this.throwOnRequestPermission = false,
    this.contacts = const <ContactModel>[],
    this._cachedContacts,
  });

  bool permissionGranted = true;
  bool throwOnRequestPermission;
  bool throwOnGetContacts = false;
  List<ContactModel> contacts;
  List<ContactModel>? _cachedContacts;
  int loadCachedContactsCalls = 0;
  int refreshCachedContactsCalls = 0;
  int refreshContactsCalls = 0;
  Completer<void>? loadCachedContactsGate;
  @override
  final contactsStreamValue = StreamValue<List<ContactModel>?>(
    defaultValue: null,
  );

  @override
  Future<bool> requestPermission() async {
    if (throwOnRequestPermission) {
      throw Exception('request permission failed');
    }
    return permissionGranted;
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    if (throwOnGetContacts) {
      throw Exception('get contacts failed');
    }
    return contacts;
  }

  @override
  Future<void> initializeContacts() async {
    await refreshContacts();
  }

  @override
  Future<void> loadCachedContacts() async {
    loadCachedContactsCalls += 1;
    await loadCachedContactsGate?.future;
    contactsStreamValue.addValue(_cachedContacts ?? contacts);
  }

  @override
  Future<void> refreshCachedContacts() async {
    refreshCachedContactsCalls += 1;
    await loadCachedContacts();
    if (contactsStreamValue.value != null) {
      return;
    }

    await refreshContacts();
  }

  @override
  Future<void> refreshContacts() async {
    refreshContactsCalls += 1;
    final loadedContacts = await getContacts();
    _cachedContacts = loadedContacts;
    contactsStreamValue.addValue(loadedContacts);
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract
    implements InviteablesRepositoryContract {
  bool throwOnImportContacts = false;
  bool throwOnCreateShareCode = false;
  List<InviteableRecipient> inviteableRecipients =
      const <InviteableRecipient>[];
  List<InviteContactMatch>? importContactMatches;
  List<InviteContactMatch>? cachedImportContactMatches;
  List<SentInviteStatus> sentStatuses = const <SentInviteStatus>[];
  SentInviteSummary sentSummary = SentInviteSummary.empty();
  final sentSummariesByOccurrence = <String, SentInviteSummary>{};
  final createShareCodeGatesByOccurrence = <String, Completer<void>>{};
  final shareCodesByOccurrence = <String, String>{};
  bool throwOnSentSummary = false;
  bool throwOnSendInvites = false;
  bool acknowledgeSendInvites = true;
  final sentRecipientAccountProfileIds = <String>[];
  final sentStatusRefreshes = <Map<String, Object?>>[];
  final sentSummaryRefreshes = <Map<String, Object?>>[];
  int sendInvitesCalls = 0;
  int importContactsCalls = 0;
  int hydrateImportedContactMatchesFromCacheCalls = 0;
  int fetchInviteableRecipientsCalls = 0;
  int createShareCodeCalls = 0;
  Completer<void>? sendInvitesGate;
  Completer<void>? importContactsGate;
  Completer<void>? fetchInviteableRecipientsGate;
  Completer<void>? hydrateImportedContactMatchesFromCacheGate;

  @override
  final inviteableRecipientsStreamValue =
      StreamValue<List<InviteableRecipient>?>(defaultValue: null);

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async => const [];

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: {},
        cooldowns: {},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async => buildInviteAcceptResult(
    inviteId: inviteId.value,
    status: 'accepted',
    creditedAcceptance: true,
    attendancePolicy: 'free_confirmation_only',
    nextStep: InviteNextStep.freeConfirmationCreated,
    supersededInviteIds: const [],
  );

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async => buildInviteAcceptResult(
    inviteId: 'mock-${code.value}',
    status: 'accepted',
    creditedAcceptance: true,
    attendancePolicy: 'free_confirmation_only',
    nextStep: InviteNextStep.freeConfirmationCreated,
    supersededInviteIds: const [],
  );

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async => buildInviteDeclineResult(
    inviteId: inviteId.value,
    status: 'declined',
    groupHasOtherPending: false,
  );
  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    importContactsCalls += 1;
    await importContactsGate?.future;
    if (throwOnImportContacts) {
      throw Exception('import contacts failed');
    }
    final overriddenMatches = importContactMatches;
    if (overriddenMatches != null) {
      _materializeInviteableRecipientsFromMatches(overriddenMatches);
      return overriddenMatches;
    }

    if (contacts.isEmpty) {
      return const <InviteContactMatch>[];
    }

    final contactHash = InviteContactImportHashes.contactHashes(
      contacts.first,
      regionCode: contacts.regionCode,
    ).first;

    final matches = <InviteContactMatch>[
      InviteContactMatch(
        contactHashValue: InviteContactHashValue()..parse(contactHash),
        typeValue: InviteContactTypeValue()..parse('phone'),
        userIdValue: UserIdValue()..parse('user-1'),
        receiverAccountProfileIdValue: InviteAccountProfileIdValue()
          ..parse('profile-1'),
        displayNameValue: InviteInviterNameValue()..parse('Matched Contact'),
        profileExposureLevelValue: InviteProfileExposureLevelValue()
          ..parse('capped_profile'),
        inviteableReasons: InviteableReasons([
          InviteableReasonValue()..parse('contact_match'),
        ]),
        isInviteableValue: DomainBooleanValue()..parse('true'),
      ),
    ];
    _materializeInviteableRecipientsFromMatches(matches);
    return matches;
  }

  void _materializeInviteableRecipientsFromMatches(
    List<InviteContactMatch> matches,
  ) {
    final byProfileId = <String, InviteableRecipient>{
      for (final recipient in inviteableRecipients)
        recipient.receiverAccountProfileId: recipient,
    };

    for (final match in matches) {
      if (!match.isInviteable ||
          match.receiverAccountProfileId.trim().isEmpty) {
        continue;
      }
      byProfileId[match.receiverAccountProfileId] = InviteableRecipient(
        userIdValue: UserIdValue()..parse(match.userId),
        receiverAccountProfileIdValue: InviteAccountProfileIdValue()
          ..parse(match.receiverAccountProfileId),
        displayNameValue: InviteInviterNameValue()..parse(match.displayName),
        avatarValue: match.avatarValue,
        profileExposureLevelValue: InviteProfileExposureLevelValue()
          ..parse(match.profileExposureLevel),
        inviteableReasons: match.inviteableReasons,
        isInviteableValue: DomainBooleanValue()..parse('true'),
        contactHashValue: InviteContactHashValue()..parse(match.contactHash),
        contactTypeValue: InviteContactTypeValue()..parse(match.type),
      );
    }

    inviteableRecipients = byProfileId.values.toList(growable: false);
    inviteableRecipientsStreamValue.addValue(inviteableRecipients);
  }

  @override
  Future<List<InviteContactMatch>?> hydrateImportedContactMatchesFromCache(
    InviteContacts contacts,
  ) async {
    hydrateImportedContactMatchesFromCacheCalls += 1;
    await hydrateImportedContactMatchesFromCacheGate?.future;
    final cachedMatches = cachedImportContactMatches;
    if (cachedMatches == null) {
      return null;
    }
    importedContactMatchesStreamValue.addValue(cachedMatches);
    return cachedMatches;
  }

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async {
    fetchInviteableRecipientsCalls += 1;
    await fetchInviteableRecipientsGate?.future;
    inviteableRecipientsStreamValue.addValue(inviteableRecipients);
    return inviteableRecipients;
  }

  @override
  Future<void> refreshInviteableRecipients() async {
    final recipients = await fetchInviteableRecipients();
    inviteableRecipientsStreamValue.addValue(recipients);
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    createShareCodeCalls += 1;
    await createShareCodeGatesByOccurrence[occurrenceId.value]?.future;
    if (throwOnCreateShareCode) {
      throw Exception('share code failed');
    }
    return buildInviteShareCodeResult(
      code: shareCodesByOccurrence[occurrenceId.value] ?? 'SHARE-CODE',
      eventId: eventId.value,
      occurrenceId: occurrenceId.value,
    );
  }

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventSlug,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {
    sendInvitesCalls += 1;
    await sendInvitesGate?.future;
    if (throwOnSendInvites) {
      throw Exception('send failed');
    }
    sentRecipientAccountProfileIds.addAll(
      recipients.items.map((recipient) => recipient.accountProfileId),
    );
    if (!acknowledgeSendInvites) {
      return;
    }

    final acknowledged = recipients.items
        .where((recipient) => recipient.accountProfileId.trim().isNotEmpty)
        .map(_pendingSentStatus)
        .toList(growable: false);
    if (acknowledged.isEmpty) {
      return;
    }

    final occurrenceKey = invitesRepoString(
      occurrenceId.value,
      defaultValue: '',
      isRequired: true,
    );
    sentInvitesByOccurrenceStreamValue.addValue({
      ...sentInvitesByOccurrenceStreamValue.value,
      occurrenceKey: acknowledged,
    });
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString occurrenceId,
  ) async {
    for (final entry in sentInvitesByOccurrenceStreamValue.value.entries) {
      if (entry.key.value.trim() == occurrenceId.value.trim()) {
        return entry.value;
      }
    }
    return const <SentInviteStatus>[];
  }

  @override
  Future<List<SentInviteStatus>> refreshSentInvitesForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    Iterable<InvitesRepositoryContractPrimString> recipientAccountProfileIds =
        const <InvitesRepositoryContractPrimString>[],
  }) async {
    final recipientFilter = recipientAccountProfileIds
        .map((value) => value.value)
        .toSet();
    sentStatusRefreshes.add({
      'occurrence_id': occurrenceId.value,
      'event_id': eventId?.value,
      'recipient_account_profile_ids': recipientFilter.toList(),
    });
    final filteredStatuses = sentStatuses
        .where(
          (status) =>
              recipientFilter.isEmpty ||
              recipientFilter.contains(status.friend.accountProfileId),
        )
        .toList(growable: false);
    final nextStatuses = recipientFilter.isEmpty
        ? filteredStatuses
        : _mergeSentStatuses(
            getSentInvitesForOccurrenceSync(occurrenceId),
            filteredStatuses,
          );

    sentInvitesByOccurrenceStreamValue.addValue({
      ...sentInvitesByOccurrenceStreamValue.value,
      occurrenceId: nextStatuses,
    });
    return nextStatuses;
  }

  List<SentInviteStatus> getSentInvitesForOccurrenceSync(
    InvitesRepositoryContractPrimString occurrenceId,
  ) {
    for (final entry in sentInvitesByOccurrenceStreamValue.value.entries) {
      if (entry.key.value.trim() == occurrenceId.value.trim()) {
        return entry.value;
      }
    }
    return const <SentInviteStatus>[];
  }

  List<SentInviteStatus> _mergeSentStatuses(
    List<SentInviteStatus> current,
    List<SentInviteStatus> updates,
  ) {
    final byRecipient = <String, SentInviteStatus>{
      for (final status in current) status.friend.accountProfileId: status,
    };
    for (final status in updates) {
      byRecipient[status.friend.accountProfileId] = status;
    }
    return byRecipient.values.toList(growable: false);
  }

  @override
  Future<SentInviteSummary> refreshSentInviteSummaryForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    InvitesRepositoryContractPrimInt? previewLimit,
  }) async {
    if (throwOnSentSummary) {
      throw Exception('sent summary failed');
    }
    sentSummaryRefreshes.add({
      'occurrence_id': occurrenceId.value,
      'event_id': eventId?.value,
      'preview_limit': previewLimit?.value,
    });
    return sentSummariesByOccurrence[occurrenceId.value] ?? sentSummary;
  }
}

InviteModel _buildInvite({
  String eventId = 'event-1',
  String occurrenceId = 'occurrence-1',
}) {
  return buildInviteModelFromPrimitives(
    id: 'invite-1',
    eventId: eventId,
    eventName: 'Evento Teste',
    occurrenceId: occurrenceId,
    eventDateTime: DateTime(2026, 3, 13, 20),
    eventImageUrl: 'https://example.com/event.jpg',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Bora?',
    tags: const ['music'],
    inviterName: 'Amigo',
  );
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'personal',
        'label': 'Personal',
        'allowed_taxonomies': [],
        'capabilities': {'is_favoritable': true, 'is_poi_enabled': false},
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

void main() {
  test(
    'init does not keep loading state when contact permission throws',
    () async {
      final contactsRepository = _FakeContactsRepository(
        throwOnRequestPermission: true,
      );
      final controller = InviteShareScreenController(
        invitesRepository: _FakeInvitesRepository(),
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(controller.contactsPermissionGranted.value, isFalse);
      expect(_friendSuggestions(controller), isEmpty);
      expect(controller.sentInvitesStreamValue.value, isEmpty);
      expect(controller.shareCodeStreamValue.value?.code, 'SHARE-CODE');

      await controller.onDispose();
    },
  );

  test(
    'init falls back to empty friend suggestions when import contacts fails',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato 1',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..throwOnImportContacts = true;
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(_friendSuggestions(controller), isEmpty);
      expect(controller.sentInvitesStreamValue.value, isEmpty);
      expect(controller.shareCodeStreamValue.value?.code, 'SHARE-CODE');

      await controller.onDispose();
    },
  );

  test(
    'init still shows backend inviteables when contact import fails',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato 1',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..throwOnImportContacts = true
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Favorite Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['favorite_by_you'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(_friendSuggestions(controller), hasLength(1));
      expect(
        _friendSuggestions(controller).single.friend.name,
        'Favorite Contact',
      );

      await controller.onDispose();
    },
  );

  test(
    'init uses backend inviteables and sends account-profile recipient identity',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato 1',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>[
              'contact_match',
              'favorite_by_you',
              'favorited_you',
              'friend',
            ],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      final suggestion = _friendSuggestions(controller).single.friend;
      expect(suggestion.accountProfileId, 'profile-1');
      expect(suggestion.matchLabel, 'Amigo no Belluga');

      controller.selectInviteableReason('friend');
      expect(controller.selectedInviteableReasonStreamValue.value, 'friend');
      controller.selectInviteableReason(null);
      expect(controller.selectedInviteableReasonStreamValue.value, isNull);

      await controller.sendInviteToFriend(suggestion);

      expect(invitesRepository.sentRecipientAccountProfileIds, ['profile-1']);

      await controller.onDispose();
    },
  );

  test(
    'sendInviteToFriend publishes pending state when post-send summary sync fails',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ]
        ..throwOnSentSummary = true;
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      final suggestion = _friendSuggestions(controller).single.friend;
      await controller.sendInviteToFriend(suggestion);

      expect(invitesRepository.sentRecipientAccountProfileIds, ['profile-1']);
      expect(controller.sendingInviteRecipientKeysStreamValue.value, isEmpty);
      expect(
        _friendSuggestions(controller).single.inviteStatus,
        InviteStatus.pending,
      );
      expect(
        controller.sentInvitesStreamValue.value.single.friend.accountProfileId,
        'profile-1',
      );

      await controller.onDispose();
    },
  );

  test(
    'sendInviteToFriend ignores duplicate taps while the same recipient is in flight',
    () async {
      final sendGate = Completer<void>();
      final invitesRepository = _FakeInvitesRepository()
        ..sendInvitesGate = sendGate
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      final suggestion = _friendSuggestions(controller).single.friend;
      final firstSend = controller.sendInviteToFriend(suggestion);
      final secondSend = controller.sendInviteToFriend(suggestion);
      await Future<void>.delayed(Duration.zero);

      expect(invitesRepository.sendInvitesCalls, 1);
      expect(
        controller.sendingInviteRecipientKeysStreamValue.value,
        contains('occurrence:occurrence-1|account_profile:profile-1'),
      );

      sendGate.complete();
      await Future.wait([firstSend, secondSend]);

      expect(invitesRepository.sendInvitesCalls, 1);
      expect(controller.sendingInviteRecipientKeysStreamValue.value, isEmpty);

      await controller.onDispose();
    },
  );

  test(
    'init resets stale send failure and in-flight invite state on occurrence switch',
    () async {
      final sendGate = Completer<void>();
      final invitesRepository = _FakeInvitesRepository()
        ..sendInvitesGate = sendGate
        ..throwOnSendInvites = true
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      final suggestion = _friendSuggestions(controller).single.friend;
      final firstSend = controller.sendInviteToFriend(suggestion);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.sendingInviteRecipientKeysStreamValue.value,
        isNotEmpty,
      );

      await controller.init(
        _buildInvite(eventId: 'event-2', occurrenceId: 'occurrence-2'),
      );

      expect(controller.inviteSendFailedStreamValue.value, isFalse);
      expect(controller.sendingInviteRecipientKeysStreamValue.value, isEmpty);

      sendGate.complete();
      await firstSend;

      expect(controller.inviteSendFailedStreamValue.value, isFalse);
      expect(controller.sendingInviteRecipientKeysStreamValue.value, isEmpty);

      await controller.onDispose();
    },
  );

  test(
    'stale in-flight send does not publish pending status after occurrence switch',
    () async {
      final sendGate = Completer<void>();
      final invitesRepository = _FakeInvitesRepository()
        ..sendInvitesGate = sendGate
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      final suggestion = _friendSuggestions(controller).single.friend;
      final firstSend = controller.sendInviteToFriend(suggestion);
      await Future<void>.delayed(Duration.zero);

      await controller.init(
        _buildInvite(eventId: 'event-2', occurrenceId: 'occurrence-2'),
      );

      sendGate.complete();
      await firstSend;

      expect(invitesRepository.sendInvitesCalls, 1);
      expect(controller.inviteSendFailedStreamValue.value, isFalse);
      expect(controller.sentInvitesStreamValue.value, isEmpty);
      expect(_friendSuggestions(controller).single.inviteStatus, isNull);

      await controller.onDispose();
    },
  );

  test(
    'stale post-send sync does not publish status after occurrence switch',
    () async {
      final syncGate = Completer<void>();
      final invitesRepository = _FakeInvitesRepository()
        ..sentSummariesByOccurrence['occurrence-1'] = _sentSummary(
          pending: 1,
          accepted: 0,
        )
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      invitesRepository.fetchInviteableRecipientsGate = syncGate;
      final suggestion = _friendSuggestions(controller).single.friend;
      final firstSend = controller.sendInviteToFriend(suggestion);
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.sentInvitesStreamValue.value.single.friend.accountProfileId,
        'profile-1',
      );
      expect(
        _friendSuggestions(controller).single.inviteStatus,
        InviteStatus.pending,
      );

      final reinit = controller.init(
        _buildInvite(eventId: 'event-2', occurrenceId: 'occurrence-2'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.inviteSendFailedStreamValue.value, isFalse);
      expect(controller.sendingInviteRecipientKeysStreamValue.value, isEmpty);
      expect(controller.sentInvitesStreamValue.value, isEmpty);
      expect(controller.sentInviteSummaryStreamValue.value.pending, 0);

      syncGate.complete();
      await Future.wait([firstSend, reinit]);

      expect(controller.inviteSendFailedStreamValue.value, isFalse);
      expect(controller.sendingInviteRecipientKeysStreamValue.value, isEmpty);
      expect(controller.sentInvitesStreamValue.value, isEmpty);
      expect(controller.sentInviteSummaryStreamValue.value.pending, 0);
      expect(_friendSuggestions(controller).single.inviteStatus, isNull);

      await controller.onDispose();
    },
  );

  test(
    'sendInviteToFriend preserves pending state when post-send refresh succeeds stale',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      final suggestion = _friendSuggestions(controller).single.friend;
      await controller.sendInviteToFriend(suggestion);

      expect(invitesRepository.sendInvitesCalls, 1);
      expect(controller.inviteSendFailedStreamValue.value, isFalse);
      expect(
        _friendSuggestions(controller).single.inviteStatus,
        InviteStatus.pending,
      );
      expect(
        controller.sentInvitesStreamValue.value.single.friend.accountProfileId,
        'profile-1',
      );

      await controller.onDispose();
    },
  );

  test(
    'sendInviteToFriend surfaces failure when send is not acknowledged',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..acknowledgeSendInvites = false
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      final suggestion = _friendSuggestions(controller).single.friend;
      await controller.sendInviteToFriend(suggestion);

      expect(invitesRepository.sendInvitesCalls, 1);
      expect(controller.inviteSendFailedStreamValue.value, isTrue);
      expect(_friendSuggestions(controller).single.inviteStatus, isNull);
      expect(controller.sentInvitesStreamValue.value, isEmpty);

      await controller.onDispose();
    },
  );

  test(
    'init hydrates occurrence sent statuses from backend and merges by account profile',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ]
        ..sentStatuses = <SentInviteStatus>[
          SentInviteStatus(
            friend: EventFriendResume(
              idValue: UserIdValue()..parse('user-1'),
              accountProfileIdValue: InviteAccountProfileIdValue()
                ..parse('profile-1'),
              displayNameValue: UserDisplayNameValue()
                ..parse('Matched Contact'),
              avatarUrlValue: UserAvatarValue(),
            ),
            status: InviteStatus.accepted,
            sentAtValue: DateTimeValue()..parse('2026-05-23T12:00:00Z'),
          ),
        ]
        ..sentSummary = _sentSummary(pending: 0, accepted: 1);
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(invitesRepository.sentStatusRefreshes, [
        {
          'occurrence_id': 'occurrence-1',
          'event_id': 'event-1',
          'recipient_account_profile_ids': ['profile-1'],
        },
      ]);
      expect(invitesRepository.sentSummaryRefreshes, [
        {
          'occurrence_id': 'occurrence-1',
          'event_id': 'event-1',
          'preview_limit': null,
        },
      ]);
      expect(controller.sentInviteSummaryStreamValue.value.accepted, 1);
      expect(
        _friendSuggestions(controller).single.inviteStatus,
        InviteStatus.accepted,
      );

      await controller.onDispose();
    },
  );

  test(
    'init preserves declined and superseded sent statuses instead of flattening to pending',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-declined',
            accountProfileId: 'profile-declined',
            displayName: 'Pessoa Recusou',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
          buildInviteableRecipient(
            userId: 'user-superseded',
            accountProfileId: 'profile-superseded',
            displayName: 'Pessoa Confirmada',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ]
        ..sentStatuses = <SentInviteStatus>[
          SentInviteStatus(
            friend: EventFriendResume(
              idValue: UserIdValue()..parse('user-declined'),
              accountProfileIdValue: InviteAccountProfileIdValue()
                ..parse('profile-declined'),
              displayNameValue: UserDisplayNameValue()..parse('Pessoa Recusou'),
              avatarUrlValue: UserAvatarValue(),
            ),
            status: InviteStatus.declined,
            sentAtValue: DateTimeValue()..parse('2026-05-23T12:00:00Z'),
            respondedAtValue: DateTimeValue()..parse('2026-05-23T12:05:00Z'),
          ),
          SentInviteStatus(
            friend: EventFriendResume(
              idValue: UserIdValue()..parse('user-superseded'),
              accountProfileIdValue: InviteAccountProfileIdValue()
                ..parse('profile-superseded'),
              displayNameValue: UserDisplayNameValue()
                ..parse('Pessoa Confirmada'),
              avatarUrlValue: UserAvatarValue(),
            ),
            status: InviteStatus.superseded,
            sentAtValue: DateTimeValue()..parse('2026-05-23T12:01:00Z'),
            respondedAtValue: DateTimeValue()..parse('2026-05-23T12:06:00Z'),
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      final statusesByName = <String, InviteStatus?>{
        for (final suggestion in _friendSuggestions(controller))
          suggestion.friend.name: suggestion.inviteStatus,
      };
      expect(statusesByName['Pessoa Recusou'], InviteStatus.declined);
      expect(statusesByName['Pessoa Confirmada'], InviteStatus.superseded);

      await controller.onDispose();
    },
  );

  test(
    'refreshPhoneContacts exposes bounded refresh state and reloads inviteables',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());
      expect(invitesRepository.fetchInviteableRecipientsCalls, 1);

      invitesRepository.inviteableRecipients = <InviteableRecipient>[
        buildInviteableRecipient(
          userId: 'user-2',
          accountProfileId: 'profile-2',
          displayName: 'Bia Favorita',
          profileExposureLevel: 'full_profile',
          inviteableReasons: const <String>['favorite_by_you'],
        ),
      ];

      await controller.refreshPhoneContacts();

      expect(controller.isPhoneContactsRefreshingStreamValue.value, isFalse);
      expect(invitesRepository.fetchInviteableRecipientsCalls, 2);
      expect(_friendSuggestions(controller).single.friend.name, 'Bia Favorita');

      await controller.onDispose();
    },
  );

  test(
    'refreshPhoneContacts merges newly imported contact matches with backend inviteables',
    () async {
      final contactsRepository = _FakeContactsRepository();
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-2',
            accountProfileId: 'profile-2',
            displayName: 'Bia Favorita',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['favorite_by_you'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(_friendSuggestions(controller).map((item) => item.friend.name), [
        'Bia Favorita',
      ]);

      contactsRepository.contacts = <ContactModel>[
        buildContactModel(
          id: 'contact-1',
          displayName: 'Matched Contact',
          phones: <String>['+55 27 99999-9999'],
        ),
      ];

      await controller.refreshPhoneContacts();

      expect(
        _friendSuggestions(controller).map((item) => item.friend.name).toList(),
        ['Bia Favorita', 'Matched Contact'],
      );

      await controller.onDispose();
    },
  );

  test(
    'init hydrates cached contacts for display without reading device contacts',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'cached-contact',
            displayName: 'Contato Cache',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(contactsRepository.loadCachedContactsCalls, 1);
      expect(contactsRepository.refreshCachedContactsCalls, 0);
      expect(contactsRepository.refreshContactsCalls, 0);
      expect(
        _friendSuggestions(controller).map((item) => item.friend.name),
        isEmpty,
      );

      await controller.onDispose();
    },
  );

  test(
    'reopening invite share keeps current app pane data visible while silent refresh resolves',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());
      expect(
        controller.friendsSuggestionsStreamValue.value?.single.friend.name,
        'Ana Contato',
      );

      final refreshGate = Completer<void>();
      invitesRepository.fetchInviteableRecipientsGate = refreshGate;
      invitesRepository.inviteableRecipients = <InviteableRecipient>[
        buildInviteableRecipient(
          userId: 'user-2',
          accountProfileId: 'profile-2',
          displayName: 'Bia Favorita',
          profileExposureLevel: 'full_profile',
          inviteableReasons: const <String>['favorite_by_you'],
        ),
      ];

      final refreshFuture = controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(
        controller.friendsSuggestionsStreamValue.value?.single.friend.name,
        'Ana Contato',
      );

      refreshGate.complete();
      await refreshFuture;

      expect(
        controller.friendsSuggestionsStreamValue.value?.single.friend.name,
        'Bia Favorita',
      );

      await controller.onDispose();
    },
  );

  test(
    'reopening invite share with a new controller hydrates cached app pane before silent refresh resolves',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final contactsRepository = _FakeContactsRepository();
      final firstController = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await firstController.init(_buildInvite());
      expect(
        firstController.friendsSuggestionsStreamValue.value?.single.friend.name,
        'Ana Contato',
      );

      final refreshGate = Completer<void>();
      invitesRepository.fetchInviteableRecipientsGate = refreshGate;
      invitesRepository.inviteableRecipients = <InviteableRecipient>[
        buildInviteableRecipient(
          userId: 'user-2',
          accountProfileId: 'profile-2',
          displayName: 'Bia Favorita',
          profileExposureLevel: 'full_profile',
          inviteableReasons: const <String>['favorite_by_you'],
        ),
      ];

      final reopenedController = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      final refreshFuture = reopenedController.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(
        reopenedController
            .friendsSuggestionsStreamValue
            .value
            ?.single
            .friend
            .name,
        'Ana Contato',
      );

      refreshGate.complete();
      await refreshFuture;

      expect(
        reopenedController
            .friendsSuggestionsStreamValue
            .value
            ?.single
            .friend
            .name,
        'Bia Favorita',
      );

      await firstController.onDispose();
      await reopenedController.onDispose();
    },
  );

  test(
    'reopening invite share keeps cached app pane when occurrence summary refresh fails',
    () async {
      final cachedInviteables = <InviteableRecipient>[
        buildInviteableRecipient(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: 'Ana Contato',
          inviteableReasons: const <String>['contact_match'],
        ),
        buildInviteableRecipient(
          userId: 'user-2',
          accountProfileId: 'profile-2',
          displayName: 'Bia Favorita',
          profileExposureLevel: 'full_profile',
          inviteableReasons: const <String>['favorite_by_you'],
        ),
      ];
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = cachedInviteables
        ..throwOnSentSummary = true;
      invitesRepository.inviteableRecipientsStreamValue.addValue(
        cachedInviteables,
      );
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(
        _friendSuggestions(controller).map((item) => item.friend.name).toList(),
        ['Ana Contato', 'Bia Favorita'],
      );

      await controller.onDispose();
    },
  );

  test(
    'init starts backend inviteables refresh without waiting for cached contacts load',
    () async {
      final loadGate = Completer<void>();
      final fetchGate = Completer<void>();
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Cache',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      )..loadCachedContactsGate = loadGate;
      final invitesRepository = _FakeInvitesRepository()
        ..fetchInviteableRecipientsGate = fetchGate
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['favorite_by_you'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      final initFuture = controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(contactsRepository.loadCachedContactsCalls, 1);
      expect(invitesRepository.fetchInviteableRecipientsCalls, 1);

      loadGate.complete();
      fetchGate.complete();
      await initFuture;
      await controller.onDispose();
    },
  );

  test(
    'init starts backend inviteables refresh without waiting for imported-match cache hydration',
    () async {
      final hydrateGate = Completer<void>();
      final fetchGate = Completer<void>();
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Cache',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..hydrateImportedContactMatchesFromCacheGate = hydrateGate
        ..fetchInviteableRecipientsGate = fetchGate
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['favorite_by_you'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      final initFuture = controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(invitesRepository.hydrateImportedContactMatchesFromCacheCalls, 1);
      expect(invitesRepository.fetchInviteableRecipientsCalls, 1);

      hydrateGate.complete();
      fetchGate.complete();
      await initFuture;
      await controller.onDispose();
    },
  );

  test(
    'cold controller init does not hydrate app pane from persisted contact matches before inviteables refresh resolves',
    () async {
      final matchedContact = buildContactModel(
        id: 'matched-contact',
        displayName: 'Bruna',
        phones: <String>['+55 27 99886-9802'],
      );
      final matchedHash = InviteContactImportHashes.contactHashes(
        matchedContact,
        regionCode: 'BR',
      ).first;
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[matchedContact],
      );
      final refreshGate = Completer<void>();
      final importGate = Completer<void>();
      final invitesRepository = _FakeInvitesRepository()
        ..cachedImportContactMatches = <InviteContactMatch>[
          InviteContactMatch(
            contactHashValue: InviteContactHashValue()..parse(matchedHash),
            typeValue: InviteContactTypeValue()..parse('phone'),
            userIdValue: UserIdValue()..parse('user-1'),
            receiverAccountProfileIdValue: InviteAccountProfileIdValue()
              ..parse('profile-1'),
            displayNameValue: InviteInviterNameValue()..parse('Bruna'),
            profileExposureLevelValue: InviteProfileExposureLevelValue()
              ..parse('capped_profile'),
            inviteableReasons: InviteableReasons([
              InviteableReasonValue()..parse('contact_match'),
            ]),
            isInviteableValue: DomainBooleanValue()..parse('true'),
          ),
        ]
        ..importContactsGate = importGate
        ..fetchInviteableRecipientsGate = refreshGate;
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
        contactRegionCode: 'BR',
      );

      final initFuture = controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(invitesRepository.hydrateImportedContactMatchesFromCacheCalls, 1);
      expect(controller.friendsSuggestionsStreamValue.value, isNull);

      importGate.complete();
      refreshGate.complete();
      await initFuture;
      expect(controller.friendsSuggestionsStreamValue.value, isEmpty);
      await controller.onDispose();
    },
  );

  test(
    'empty cached imported matches do not resolve the app pane before inviteables refresh returns',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Cache',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      );
      final refreshGate = Completer<void>();
      final importGate = Completer<void>();
      final invitesRepository = _FakeInvitesRepository()
        ..cachedImportContactMatches = const <InviteContactMatch>[]
        ..importContactsGate = importGate
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ]
        ..fetchInviteableRecipientsGate = refreshGate;

      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );

      final initFuture = controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(controller.friendsSuggestionsStreamValue.value, isNull);
      expect(
        controller.externalContactShareTargetsStreamValue.value,
        hasLength(1),
      );

      importGate.complete();
      refreshGate.complete();
      await initFuture;

      expect(
        controller.friendsSuggestionsStreamValue.value?.single.friend.name,
        'Ana Contato',
      );

      await controller.onDispose();
    },
  );

  test(
    'app pane starts inviteables refresh without route-critical contact import',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Cache',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      );
      final fetchGate = Completer<void>();
      final invitesRepository = _FakeInvitesRepository()
        ..fetchInviteableRecipientsGate = fetchGate
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      final initFuture = controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(invitesRepository.fetchInviteableRecipientsCalls, 1);
      expect(controller.friendsSuggestionsStreamValue.value, isNull);

      fetchGate.complete();
      await initFuture;

      await Future<void>.delayed(Duration.zero);

      expect(invitesRepository.importContactsCalls, 0);
      expect(
        controller.friendsSuggestionsStreamValue.value?.single.friend.name,
        'Ana Contato',
      );

      await controller.onDispose();
    },
  );

  test(
    'app pane init keeps request budget with large cached contact set',
    () async {
      final largeContacts = List<ContactModel>.generate(
        1200,
        (index) => buildContactModel(
          id: 'contact-$index',
          displayName: 'Contato $index',
          phones: <String>['+55 27 99999-${index.toString().padLeft(4, '0')}'],
        ),
      );
      final contactsRepository = _FakeContactsRepository(
        cachedContacts: largeContacts,
      );
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
          buildInviteableRecipient(
            userId: 'user-2',
            accountProfileId: 'profile-2',
            displayName: 'Bia Favorita',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['favorite_by_you'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(contactsRepository.loadCachedContactsCalls, 1);
      expect(contactsRepository.refreshContactsCalls, 0);
      expect(invitesRepository.importContactsCalls, 0);
      expect(invitesRepository.fetchInviteableRecipientsCalls, 1);
      expect(invitesRepository.sentStatusRefreshes, hasLength(1));
      expect(invitesRepository.sentSummaryRefreshes, hasLength(1));
      expect(
        invitesRepository
            .sentStatusRefreshes
            .single['recipient_account_profile_ids'],
        ['profile-1', 'profile-2'],
      );
      expect(_friendSuggestions(controller), hasLength(2));

      await controller.onDispose();
    },
  );

  test(
    'app pane skips local contact hash resolution when backend inviteables have no contact hash',
    () async {
      var localContactHashResolverCalls = 0;
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Cache',
            phones: <String>['+55 27 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['favorite_by_you'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        localContactHashResolver: (contact, {regionCode}) {
          localContactHashResolverCalls += 1;
          return InviteContactImportHashes.contactHashes(
            contact,
            regionCode: regionCode,
          );
        },
      );

      await controller.init(_buildInvite());

      expect(localContactHashResolverCalls, 0);
      expect(_friendSuggestions(controller).single.friend.name, 'Ana Contato');

      await controller.onDispose();
    },
  );

  test(
    'init uses cached agenda name for backend account contact matches',
    () async {
      final matchedContact = buildContactModel(
        id: 'matched-contact',
        displayName: 'Bruna',
        phones: <String>['+55 27 99886-9802'],
      );
      final matchedHash = InviteContactImportHashes.contactHashes(
        matchedContact,
        regionCode: 'BR',
      ).first;
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[matchedContact],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[]
        ..inviteableRecipients = <InviteableRecipient>[
          _buildContactMatchedInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: '+55 27 99886-9802',
            contactHash: matchedHash,
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
        contactRegionCode: 'BR',
      );

      await controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(contactsRepository.loadCachedContactsCalls, 1);
      expect(contactsRepository.refreshCachedContactsCalls, 0);
      expect(contactsRepository.refreshContactsCalls, 0);
      expect(invitesRepository.importContactsCalls, 0);
      expect(_friendSuggestions(controller).single.friend.name, 'Bruna');

      await controller.onDispose();
    },
  );

  test(
    'selecting Telefone loads cached contacts without forcing device reload',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'cached-contact',
            displayName: 'Contato Cache',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(contactsRepository.refreshCachedContactsCalls, 0);
      expect(contactsRepository.refreshContactsCalls, 0);
      expect(_externalTargets(controller), isNotEmpty);

      await controller.onDispose();
    },
  );

  test(
    'selecting Telefone reads device contacts when the cached Agenda is empty',
    () async {
      final contactsRepository = _FakeContactsRepository(
        cachedContacts: const <ContactModel>[],
        contacts: <ContactModel>[
          buildContactModel(
            id: 'device-contact',
            displayName: 'Contato Device',
            phones: <String>['+55 27 98888-7777'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(contactsRepository.refreshContactsCalls, 1);
      expect(_externalTargets(controller), hasLength(1));
      expect(_externalTargets(controller).single.displayName, 'Contato Device');

      await controller.onDispose();
    },
  );

  test(
    'reopening invite share republishes Agenda targets from repository cache even when the controller kept a stale empty phone pane',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'cached-contact',
            displayName: 'Contato Cache',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );

      await controller.init(_buildInvite());
      controller.externalContactShareTargetsStreamValue.addValue(
        const <InviteExternalContactShareTarget>[],
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(_externalTargets(controller), hasLength(1));
      expect(_externalTargets(controller).single.displayName, 'Contato Cache');

      await controller.onDispose();
    },
  );

  test(
    'selecting Telefone publishes cached Agenda contacts even before imported-match cache is available',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'cached-contact',
            displayName: 'Contato Cache',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[]
        ..fetchInviteableRecipientsGate = Completer<void>();
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );

      final initFuture = controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);
      await controller.selectPane(InviteSharePane.phone);

      expect(contactsRepository.loadCachedContactsCalls, 1);
      expect(contactsRepository.refreshCachedContactsCalls, 0);
      expect(_externalTargets(controller), hasLength(1));
      expect(_externalTargets(controller).single.displayName, 'Contato Cache');

      invitesRepository.fetchInviteableRecipientsGate?.complete();
      await initFuture;
      await controller.onDispose();
    },
  );

  test(
    'Telefone pane exposes unmatched local contacts as native external share targets',
    () async {
      final matchedContact = buildContactModel(
        id: 'matched-contact',
        displayName: 'Matched Contact',
        phones: <String>['+55 27 99999-9999'],
      );
      final matchedHash = InviteContactImportHashes.contactHashes(
        matchedContact,
        regionCode: 'BR',
      ).first;
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          matchedContact,
          buildContactModel(
            id: 'external-contact',
            displayName: 'Mae',
            phones: <String>['+55 27 98888-7777'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          _buildContactMatchedInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Matched Contact',
            contactHash: matchedHash,
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
        contactRegionCode: 'BR',
      );

      await controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);
      await controller.selectPane(InviteSharePane.phone);

      expect(
        _friendSuggestions(controller).map((item) => item.friend.name),
        contains('Matched Contact'),
      );
      expect(_externalTargets(controller), hasLength(1));
      expect(_externalTargets(controller).single.displayName, 'Mae');

      await controller.onDispose();
    },
  );

  test(
    'backend contact-match hashes keep matched contacts out of Telefone pane',
    () async {
      final matchedContact = buildContactModel(
        id: 'matched-contact',
        displayName: 'Matched Backend',
        phones: <String>['+55 27 99999-9999'],
      );
      final matchedHash = InviteContactImportHashes.contactHashes(
        matchedContact,
        regionCode: 'BR',
      ).first;
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          matchedContact,
          buildContactModel(
            id: 'external-contact',
            displayName: 'Mae',
            phones: <String>['+55 27 98888-7777'],
          ),
        ],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[]
        ..inviteableRecipients = <InviteableRecipient>[
          InviteableRecipient(
            userIdValue: UserIdValue()..parse('user-1'),
            receiverAccountProfileIdValue: InviteAccountProfileIdValue()
              ..parse('profile-1'),
            displayNameValue: InviteInviterNameValue()
              ..parse('Matched Backend'),
            profileExposureLevelValue: InviteProfileExposureLevelValue()
              ..parse('capped_profile'),
            inviteableReasons: InviteableReasons([
              InviteableReasonValue()..parse('contact_match'),
            ]),
            contactHashValue: InviteContactHashValue()..parse(matchedHash),
            contactTypeValue: InviteContactTypeValue()..parse('phone'),
            isInviteableValue: DomainBooleanValue()..parse('true'),
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
        contactRegionCode: 'BR',
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(
        _friendSuggestions(controller).map((item) => item.friend.name),
        contains('Matched Backend'),
      );
      expect(
        _externalTargets(
          controller,
        ).map((target) => target.displayName).toList(),
        ['Mae'],
      );

      await controller.onDispose();
    },
  );

  test(
    'Pessoas uses local agenda name when account contact-match name is missing',
    () async {
      final matchedContact = buildContactModel(
        id: 'matched-contact',
        displayName: 'Bruna',
        phones: <String>['+55 27 99886-9802'],
      );
      final matchedHash = InviteContactImportHashes.contactHashes(
        matchedContact,
        regionCode: 'BR',
      ).first;
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[matchedContact],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[]
        ..inviteableRecipients = <InviteableRecipient>[
          _buildContactMatchedInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: '+55 27 99886-9802',
            contactHash: matchedHash,
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
        contactRegionCode: 'BR',
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(_friendSuggestions(controller).single.friend.name, 'Bruna');

      await controller.onDispose();
    },
  );

  test('Pessoas keeps account name before agenda fallback', () async {
    final matchedContact = buildContactModel(
      id: 'matched-contact',
      displayName: 'Nome da Agenda',
      phones: <String>['+55 27 99886-9802'],
    );
    final matchedHash = InviteContactImportHashes.contactHashes(
      matchedContact,
      regionCode: 'BR',
    ).first;
    final contactsRepository = _FakeContactsRepository(
      contacts: <ContactModel>[matchedContact],
    );
    final invitesRepository = _FakeInvitesRepository()
      ..importContactMatches = const <InviteContactMatch>[]
      ..inviteableRecipients = <InviteableRecipient>[
        _buildContactMatchedInviteableRecipient(
          userId: 'user-1',
          accountProfileId: 'profile-1',
          displayName: 'Nome da Account',
          contactHash: matchedHash,
        ),
      ];
    final controller = InviteShareScreenController(
      invitesRepository: invitesRepository,
      contactsRepository: contactsRepository,
      appData: _buildAppData(),
      isWebRuntime: false,
      contactRegionCode: 'BR',
    );

    await controller.init(_buildInvite());
    await controller.selectPane(InviteSharePane.phone);

    expect(
      _friendSuggestions(controller).single.friend.name,
      'Nome da Account',
    );

    await controller.onDispose();
  });

  test(
    'Pessoas falls back to linked phone when neither account nor agenda has name',
    () async {
      final matchedContact = buildContactModel(
        id: 'matched-contact',
        displayName: '',
        phones: <String>['+55 27 99886-9802'],
      );
      final matchedHash = InviteContactImportHashes.contactHashes(
        matchedContact,
        regionCode: 'BR',
      ).first;
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[matchedContact],
      );
      final invitesRepository = _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[]
        ..inviteableRecipients = <InviteableRecipient>[
          _buildContactMatchedInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: '+55 27 99886-9802',
            contactHash: matchedHash,
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
        contactRegionCode: 'BR',
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(
        _friendSuggestions(controller).single.friend.name,
        '+55 27 99886-9802',
      );

      await controller.onDispose();
    },
  );

  test('does not expose external phone contacts on web runtime', () async {
    final contactsRepository = _FakeContactsRepository(
      contacts: <ContactModel>[
        buildContactModel(
          id: 'external-contact',
          displayName: 'Mae',
          phones: <String>['+55 27 98888-7777'],
        ),
      ],
    );
    final controller = InviteShareScreenController(
      invitesRepository: _FakeInvitesRepository()
        ..importContactMatches = const <InviteContactMatch>[],
      contactsRepository: contactsRepository,
      appData: _buildAppData(),
      isWebRuntime: true,
    );

    await controller.init(_buildInvite());
    await controller.selectPane(InviteSharePane.phone);

    expect(_externalTargets(controller), isEmpty);

    await controller.onDispose();
  });

  test(
    'does not expose external phone contacts when import classification fails',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'external-contact',
            displayName: 'Mae',
            phones: <String>['+55 27 98888-7777'],
          ),
        ],
      );
      final controller = InviteShareScreenController(
        invitesRepository: _FakeInvitesRepository()
          ..throwOnImportContacts = true,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(_externalTargets(controller), hasLength(1));
      expect(_externalTargets(controller).single.displayName, 'Mae');

      await controller.onDispose();
    },
  );

  test(
    'refreshFriends surfaces import failure without dropping current inviteables',
    () async {
      final contactsRepository = _FakeContactsRepository();
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-2',
            accountProfileId: 'profile-2',
            displayName: 'Bia Favorita',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['favorite_by_you'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());
      expect(
        _friendSuggestions(controller).map((item) => item.friend.name).toList(),
        ['Bia Favorita'],
      );

      contactsRepository.contacts = <ContactModel>[
        buildContactModel(
          id: 'contact-1',
          displayName: 'Contato Novo',
          phones: <String>['+55 27 99999-9999'],
        ),
      ];
      invitesRepository.throwOnImportContacts = true;

      await controller.refreshPhoneContacts();

      expect(controller.isPhoneContactsRefreshingStreamValue.value, isFalse);
      expect(controller.phoneContactsRefreshFailedStreamValue.value, isTrue);
      expect(
        _friendSuggestions(controller).map((item) => item.friend.name).toList(),
        ['Bia Favorita'],
      );

      await controller.onDispose();
    },
  );

  test(
    'refreshFriends drops duplicate refresh while a refresh is in flight',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );
      await controller.init(_buildInvite());

      final gate = Completer<void>();
      invitesRepository.fetchInviteableRecipientsGate = gate;

      final firstRefresh = controller.refreshPhoneContacts();
      await Future<void>.delayed(Duration.zero);
      final duplicateRefresh = controller.refreshPhoneContacts();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isPhoneContactsRefreshingStreamValue.value, isTrue);
      expect(invitesRepository.fetchInviteableRecipientsCalls, 2);

      gate.complete();
      await Future.wait([firstRefresh, duplicateRefresh]);

      expect(controller.isPhoneContactsRefreshingStreamValue.value, isFalse);
      expect(invitesRepository.fetchInviteableRecipientsCalls, 2);

      await controller.onDispose();
    },
  );

  test(
    'share code failure clears generating state and can be retried',
    () async {
      final invitesRepository = _FakeInvitesRepository()
        ..throwOnCreateShareCode = true;
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(controller.isShareCodeLoadingStreamValue.value, isFalse);
      expect(controller.shareCodeStreamValue.value, isNull);
      expect(invitesRepository.createShareCodeCalls, 1);

      invitesRepository.throwOnCreateShareCode = false;
      await controller.reloadShareCode();

      expect(controller.isShareCodeLoadingStreamValue.value, isFalse);
      expect(controller.shareCodeStreamValue.value?.code, 'SHARE-CODE');
      expect(invitesRepository.createShareCodeCalls, 2);

      await controller.onDispose();
    },
  );

  test(
    'reinit while share code is loading publishes only the current occurrence code',
    () async {
      final staleShareCodeGate = Completer<void>();
      final invitesRepository = _FakeInvitesRepository()
        ..createShareCodeGatesByOccurrence['occurrence-1'] = staleShareCodeGate
        ..shareCodesByOccurrence['occurrence-1'] = 'OLD-CODE'
        ..shareCodesByOccurrence['occurrence-2'] = 'NEW-CODE'
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-2',
            accountProfileId: 'profile-2',
            displayName: 'Current Occurrence Contact',
            profileExposureLevel: 'full_profile',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );

      final firstInit = controller.init(_buildInvite());
      await Future<void>.delayed(Duration.zero);

      expect(controller.isShareCodeLoadingStreamValue.value, isTrue);
      expect(invitesRepository.createShareCodeCalls, 1);

      await controller.init(
        _buildInvite(eventId: 'event-2', occurrenceId: 'occurrence-2'),
      );

      expect(invitesRepository.createShareCodeCalls, 2);
      expect(controller.isShareCodeLoadingStreamValue.value, isFalse);
      expect(controller.shareCodeStreamValue.value?.code, 'NEW-CODE');

      staleShareCodeGate.complete();
      await firstInit;

      expect(controller.isShareCodeLoadingStreamValue.value, isFalse);
      expect(controller.shareCodeStreamValue.value?.code, 'NEW-CODE');

      await controller.onDispose();
    },
  );
}

List<InviteFriendResumeWithStatus> _friendSuggestions(
  InviteShareScreenController controller,
) =>
    controller.friendsSuggestionsStreamValue.value ??
    const <InviteFriendResumeWithStatus>[];

List<InviteExternalContactShareTarget> _externalTargets(
  InviteShareScreenController controller,
) =>
    controller.externalContactShareTargetsStreamValue.value ??
    const <InviteExternalContactShareTarget>[];

InviteableRecipient _buildContactMatchedInviteableRecipient({
  required String userId,
  required String accountProfileId,
  required String displayName,
  required String contactHash,
}) {
  return InviteableRecipient(
    userIdValue: UserIdValue()..parse(userId),
    receiverAccountProfileIdValue: InviteAccountProfileIdValue()
      ..parse(accountProfileId),
    displayNameValue: InviteInviterNameValue()..parse(displayName),
    profileExposureLevelValue: InviteProfileExposureLevelValue()
      ..parse('capped_profile'),
    inviteableReasons: InviteableReasons([
      InviteableReasonValue()..parse('contact_match'),
    ]),
    contactHashValue: InviteContactHashValue()..parse(contactHash),
    contactTypeValue: InviteContactTypeValue()..parse('phone'),
    isInviteableValue: DomainBooleanValue()..parse('true'),
  );
}

SentInviteSummary _sentSummary({required int pending, required int accepted}) {
  return SentInviteSummary(
    pendingValue: SentInviteSummaryCountValue()..parse(pending.toString()),
    acceptedValue: SentInviteSummaryCountValue()..parse(accepted.toString()),
    declinedValue: SentInviteSummaryCountValue(),
    terminalHiddenValue: SentInviteSummaryCountValue(),
    totalVisibleValue: SentInviteSummaryCountValue()
      ..parse((pending + accepted).toString()),
    totalSentValue: SentInviteSummaryCountValue()
      ..parse((pending + accepted).toString()),
  );
}

SentInviteStatus _pendingSentStatus(EventFriendResume recipient) {
  return SentInviteStatus(
    friend: recipient,
    status: InviteStatus.pending,
    sentAtValue: DateTimeValue()..parse('2026-05-23T12:00:00Z'),
  );
}
