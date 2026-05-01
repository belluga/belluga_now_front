import 'dart:async';

import 'package:belluga_now/application/invites/invite_contact_import_hashes.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
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
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';

class _FakeContactsRepository implements ContactsRepositoryContract {
  _FakeContactsRepository({
    this.throwOnRequestPermission = false,
    this.contacts = const <ContactModel>[],
  });

  bool permissionGranted = true;
  bool throwOnRequestPermission;
  bool throwOnGetContacts = false;
  List<ContactModel> contacts;
  int loadCachedContactsCalls = 0;
  int refreshCachedContactsCalls = 0;
  int refreshContactsCalls = 0;
  @override
  final contactsStreamValue =
      StreamValue<List<ContactModel>?>(defaultValue: null);

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
    contactsStreamValue.addValue(contacts);
  }

  @override
  Future<void> refreshCachedContacts() async {
    refreshCachedContactsCalls += 1;
    final loadedContacts = await getContacts();
    contactsStreamValue.addValue(loadedContacts);
  }

  @override
  Future<void> refreshContacts() async {
    refreshContactsCalls += 1;
    final loadedContacts = await getContacts();
    contactsStreamValue.addValue(loadedContacts);
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  bool throwOnImportContacts = false;
  bool throwOnCreateShareCode = false;
  List<InviteableRecipient> inviteableRecipients =
      const <InviteableRecipient>[];
  List<InviteContactMatch>? importContactMatches;
  final sentRecipientAccountProfileIds = <String>[];
  int importContactsCalls = 0;
  int fetchInviteableRecipientsCalls = 0;
  int createShareCodeCalls = 0;
  Completer<void>? fetchInviteableRecipientsGate;

  @override
  Future<List<InviteModel>> fetchInvites(
          {InvitesRepositoryContractPrimInt? page,
          InvitesRepositoryContractPrimInt? pageSize}) async =>
      const [];

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
          InvitesRepositoryContractPrimString inviteId) async =>
      buildInviteAcceptResult(
        inviteId: inviteId.value,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
          InvitesRepositoryContractPrimString code) async =>
      buildInviteAcceptResult(
        inviteId: 'mock-${code.value}',
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(
          InvitesRepositoryContractPrimString inviteId) async =>
      buildInviteDeclineResult(
        inviteId: inviteId.value,
        status: 'declined',
        groupHasOtherPending: false,
      );
  @override
  Future<List<InviteContactMatch>> importContacts(
      InviteContacts contacts) async {
    importContactsCalls += 1;
    if (throwOnImportContacts) {
      throw Exception('import contacts failed');
    }
    final overriddenMatches = importContactMatches;
    if (overriddenMatches != null) {
      return overriddenMatches;
    }

    if (contacts.isEmpty) {
      return const <InviteContactMatch>[];
    }

    final contactHash = InviteContactImportHashes.contactHashes(
      contacts.first,
      regionCode: contacts.regionCode,
    ).first;

    return <InviteContactMatch>[
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
  }

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async {
    fetchInviteableRecipientsCalls += 1;
    await fetchInviteableRecipientsGate?.future;
    return inviteableRecipients;
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    createShareCodeCalls += 1;
    if (throwOnCreateShareCode) {
      throw Exception('share code failed');
    }
    return buildInviteShareCodeResult(
      code: 'SHARE-CODE',
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
    sentRecipientAccountProfileIds.addAll(
      recipients.items.map((recipient) => recipient.accountProfileId),
    );
  }

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString eventSlug,
  ) async =>
      const <SentInviteStatus>[];
}

InviteModel _buildInvite() {
  return buildInviteModelFromPrimitives(
    id: 'invite-1',
    eventId: 'event-1',
    eventName: 'Evento Teste',
    occurrenceId: 'occurrence-1',
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
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
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
      expect(controller.friendsSuggestionsStreamValue.value, isEmpty);
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

      expect(controller.friendsSuggestionsStreamValue.value, isEmpty);
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

      expect(controller.friendsSuggestionsStreamValue.value, hasLength(1));
      expect(
        controller.friendsSuggestionsStreamValue.value.single.friend.name,
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

      final suggestion =
          controller.friendsSuggestionsStreamValue.value.single.friend;
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
      expect(
        controller.friendsSuggestionsStreamValue.value.single.friend.name,
        'Bia Favorita',
      );

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

      expect(
        controller.friendsSuggestionsStreamValue.value
            .map((item) => item.friend.name),
        ['Bia Favorita'],
      );

      contactsRepository.contacts = <ContactModel>[
        buildContactModel(
          id: 'contact-1',
          displayName: 'Matched Contact',
          phones: <String>['+55 27 99999-9999'],
        ),
      ];

      await controller.refreshPhoneContacts();

      expect(
        controller.friendsSuggestionsStreamValue.value
            .map((item) => item.friend.name)
            .toList(),
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
      final controller = InviteShareScreenController(
        invitesRepository: _FakeInvitesRepository(),
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );

      await controller.init(_buildInvite());

      expect(contactsRepository.loadCachedContactsCalls, 1);
      expect(contactsRepository.refreshCachedContactsCalls, 0);
      expect(contactsRepository.refreshContactsCalls, 0);
      expect(
        controller.friendsSuggestionsStreamValue.value
            .map((item) => item.friend.name),
        isEmpty,
      );

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

      expect(contactsRepository.loadCachedContactsCalls, 1);
      expect(contactsRepository.refreshCachedContactsCalls, 0);
      expect(contactsRepository.refreshContactsCalls, 0);
      expect(invitesRepository.importContactsCalls, 0);
      expect(
        controller.friendsSuggestionsStreamValue.value.single.friend.name,
        'Bruna',
      );

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
      final controller = InviteShareScreenController(
        invitesRepository: _FakeInvitesRepository(),
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(contactsRepository.refreshCachedContactsCalls, 1);
      expect(contactsRepository.refreshContactsCalls, 0);
      expect(
        controller.friendsSuggestionsStreamValue.value
            .map((item) => item.friend.name),
        contains('Matched Contact'),
      );

      await controller.onDispose();
    },
  );

  test(
    'Telefone pane exposes unmatched local contacts as native external share targets',
    () async {
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'matched-contact',
            displayName: 'Matched Contact',
            phones: <String>['+55 27 99999-9999'],
          ),
          buildContactModel(
            id: 'external-contact',
            displayName: 'Mae',
            phones: <String>['+55 27 98888-7777'],
          ),
        ],
      );
      final controller = InviteShareScreenController(
        invitesRepository: _FakeInvitesRepository(),
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(
        controller.friendsSuggestionsStreamValue.value
            .map((item) => item.friend.name),
        contains('Matched Contact'),
      );
      expect(
        controller.externalContactShareTargetsStreamValue.value,
        hasLength(1),
      );
      expect(
        controller
            .externalContactShareTargetsStreamValue.value.single.displayName,
        'Mae',
      );

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
        controller.friendsSuggestionsStreamValue.value
            .map((item) => item.friend.name),
        contains('Matched Backend'),
      );
      expect(
        controller.externalContactShareTargetsStreamValue.value
            .map((target) => target.displayName)
            .toList(),
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

      expect(
        controller.friendsSuggestionsStreamValue.value.single.friend.name,
        'Bruna',
      );

      await controller.onDispose();
    },
  );

  test(
    'Pessoas keeps account name before agenda fallback',
    () async {
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
        controller.friendsSuggestionsStreamValue.value.single.friend.name,
        'Nome da Account',
      );

      await controller.onDispose();
    },
  );

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
        controller.friendsSuggestionsStreamValue.value.single.friend.name,
        '+55 27 99886-9802',
      );

      await controller.onDispose();
    },
  );

  test(
    'does not expose external phone contacts on web runtime',
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
        invitesRepository: _FakeInvitesRepository(),
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: true,
      );

      await controller.init(_buildInvite());
      await controller.selectPane(InviteSharePane.phone);

      expect(controller.externalContactShareTargetsStreamValue.value, isEmpty);

      await controller.onDispose();
    },
  );

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

      expect(controller.externalContactShareTargetsStreamValue.value, isEmpty);

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
        controller.friendsSuggestionsStreamValue.value
            .map((item) => item.friend.name)
            .toList(),
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
        controller.friendsSuggestionsStreamValue.value
            .map((item) => item.friend.name)
            .toList(),
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
}

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
