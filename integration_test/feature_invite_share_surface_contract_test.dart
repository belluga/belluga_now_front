import 'dart:async';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/projections/friend_resume_with_status.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/invite_share_screen.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:belluga_now/testing/invite_accept_result_builder.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'invite share runtime shows loading-before-empty on both panes and keeps Agenda refresh scoped to Agenda',
    (tester) async {
      final invitesRepository = _FakeInvitesRepository()
        ..fetchInviteableRecipientsGate = Completer<void>();
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
        isWebRuntime: false,
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(
          home: InviteShareScreen(invite: _buildInvite()),
        ),
      );
      await tester.pump();

      expect(find.text('Tenant Test'), findsOneWidget);
      expect(find.text('Agenda'), findsOneWidget);
      expect(find.text('Carregando pessoas do app...'), findsOneWidget);
      expect(
        find.text('Nenhum contato convidável para este filtro.'),
        findsNothing,
      );
      expect(find.text('Atualizar agenda'), findsNothing);

      await tester.tap(find.text('Agenda'));
      await tester.pump();

      expect(find.text('Atualizar agenda'), findsOneWidget);
      expect(find.text('Carregando agenda...'), findsOneWidget);
      expect(
        find.text('Nenhum contato do telefone disponível.'),
        findsNothing,
      );

      invitesRepository.fetchInviteableRecipientsGate!.complete();
      await tester.pumpAndSettle();

      expect(
        find.text('Nenhum contato convidável para este filtro.'),
        findsNothing,
      );
      expect(
          find.text('Nenhum contato do telefone disponível.'), findsOneWidget);
    },
  );

  testWidgets(
    'invite share runtime preserves cached app recipients while silent refresh resolves fresh data',
    (tester) async {
      final invitesRepository = _FakeInvitesRepository()
        ..fetchInviteableRecipientsGate = Completer<void>()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-fresh',
            accountProfileId: 'profile-fresh',
            displayName: 'Fresh Friend',
            inviteableReasons: const <String>['friend'],
          ),
        ];
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(),
        appData: _buildAppData(),
      );
      controller.friendsSuggestionsStreamValue.addValue(
        <InviteFriendResumeWithStatus>[
          InviteFriendResumeWithStatus(
            friend: buildInviteableRecipient(
              userId: 'user-cached',
              accountProfileId: 'profile-cached',
              displayName: 'Cached Friend',
              inviteableReasons: const <String>['contact_match'],
            ).toFriendResume(),
          ),
        ],
      );

      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(
          home: InviteShareScreen(invite: _buildInvite()),
        ),
      );
      await tester.pump();

      expect(find.text('Cached Friend'), findsOneWidget);
      expect(find.text('Fresh Friend'), findsNothing);
      expect(
        find.text('Nenhum contato convidável para este filtro.'),
        findsNothing,
      );

      invitesRepository.fetchInviteableRecipientsGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Fresh Friend'), findsOneWidget);
      expect(find.text('Cached Friend'), findsNothing);
    },
  );

  testWidgets(
    'invite share runtime keeps app pane loading while only empty imported-match cache is available',
    (tester) async {
      final invitesRepository = _FakeInvitesRepository()
        ..cachedImportContactMatches = const <InviteContactMatch>[]
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-fresh',
            accountProfileId: 'profile-fresh',
            displayName: 'Fresh Friend',
            inviteableReasons: const <String>['friend'],
          ),
        ]
        ..fetchInviteableRecipientsGate = Completer<void>();
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: _FakeContactsRepository(
          contacts: <ContactModel>[
            buildContactModel(
              id: 'contact-1',
              displayName: 'Contato Cache',
              phones: <String>['(27) 99999-9999'],
            ),
          ],
        ),
        appData: _buildAppData(),
        isWebRuntime: false,
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(
          home: InviteShareScreen(invite: _buildInvite()),
        ),
      );
      await tester.pump();

      expect(find.text('Carregando pessoas do app...'), findsOneWidget);
      expect(
        find.text('Nenhum contato convidável para este filtro.'),
        findsNothing,
      );

      invitesRepository.fetchInviteableRecipientsGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('Fresh Friend'), findsOneWidget);
    },
  );
}

class _FakeContactsRepository implements ContactsRepositoryContract {
  _FakeContactsRepository({
    this.contacts = const <ContactModel>[],
  });

  final List<ContactModel> contacts;

  @override
  final contactsStreamValue =
      StreamValue<List<ContactModel>?>(defaultValue: null);

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<ContactModel>> getContacts() async => contacts;

  @override
  Future<void> initializeContacts() async {
    await refreshContacts();
  }

  @override
  Future<void> loadCachedContacts() async {
    contactsStreamValue.addValue(contacts);
  }

  @override
  Future<void> refreshCachedContacts() async {
    contactsStreamValue.addValue(contacts);
  }

  @override
  Future<void> refreshContacts() async {
    contactsStreamValue.addValue(contacts);
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  List<InviteableRecipient> inviteableRecipients =
      const <InviteableRecipient>[];
  List<InviteContactMatch>? cachedImportContactMatches;
  Completer<void>? fetchInviteableRecipientsGate;

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async =>
      const <InviteModel>[];

  @override
  Future<InviteRuntimeSettings> fetchSettings() async =>
      buildInviteRuntimeSettings(
        tenantId: null,
        limits: const <String, int>{},
        cooldowns: const <String, int>{},
        overQuotaMessage: null,
      );

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async =>
      buildInviteAcceptResult(
        inviteId: inviteId.value,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.none,
        supersededInviteIds: const <String>[],
      );

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) async =>
      buildInviteAcceptResult(
        inviteId: 'mock-${code.value}',
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.none,
        supersededInviteIds: const <String>[],
      );

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async =>
      buildInviteDeclineResult(
        inviteId: inviteId.value,
        status: 'declined',
        groupHasOtherPending: false,
      );

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async =>
      const <InviteContactMatch>[];

  @override
  Future<List<InviteContactMatch>?> hydrateImportedContactMatchesFromCache(
    InviteContacts contacts,
  ) async {
    final cachedMatches = cachedImportContactMatches;
    if (cachedMatches == null) {
      return null;
    }
    importedContactMatchesStreamValue.addValue(cachedMatches);
    return cachedMatches;
  }

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async {
    await fetchInviteableRecipientsGate?.future;
    return inviteableRecipients;
  }

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async =>
      buildInviteShareCodeResult(
        code: 'SHARE-CODE',
        eventId: eventId.value,
        occurrenceId: occurrenceId.value,
      );

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventSlug,
    InviteRecipients recipients, {
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}

  @override
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString occurrenceId,
  ) async =>
      const <SentInviteStatus>[];
}

InviteModel _buildInvite() {
  return buildInviteModelFromPrimitives(
    id: 'invite-1',
    eventId: 'event-1',
    occurrenceId: 'occurrence-1',
    eventName: 'Evento Teste',
    eventDateTime: DateTime(2026, 5, 2, 20),
    eventImageUrl: 'https://example.com/event.jpg',
    location: 'Guarapari',
    hostName: 'Host',
    message: 'Bora?',
    tags: const <String>['music'],
    inviterName: 'Amigo',
  );
}

AppData _buildAppData() {
  return buildAppDataFromInitialization(
    remoteData: const <String, dynamic>{
      'name': 'Tenant Test',
      'type': 'tenant',
      'main_domain': 'https://tenant.test',
      'profile_types': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'personal',
          'label': 'Personal',
          'allowed_taxonomies': <String>[],
          'capabilities': <String, dynamic>{
            'is_favoritable': true,
            'is_poi_enabled': false,
          },
        },
      ],
      'domains': <String>['https://tenant.test'],
      'app_domains': <String>[],
      'theme_data_settings': <String, dynamic>{
        'brightness_default': 'light',
        'primary_seed_color': '#FFFFFF',
        'secondary_seed_color': '#000000',
      },
      'main_color': '#FFFFFF',
      'tenant_id': 'tenant-1',
      'telemetry': <String, dynamic>{'trackers': <dynamic>[]},
      'telemetry_context': <String, dynamic>{
        'location_freshness_minutes': 5,
      },
      'firebase': null,
      'push': null,
    },
    localInfo: <String, dynamic>{
      'platformType': PlatformTypeValue()..parse('mobile'),
      'hostname': 'tenant.test',
      'href': 'https://tenant.test',
      'port': null,
      'device': 'invite-share-device-test',
    },
  );
}
