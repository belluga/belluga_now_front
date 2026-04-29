import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/inviteable_recipient.dart';
import 'package:belluga_now/domain/invites/invite_accept_result.dart';
import 'package:belluga_now/domain/invites/invite_contact_group.dart';
import 'package:belluga_now/domain/invites/invite_contact_match.dart';
import 'package:belluga_now/domain/invites/invite_decline_result.dart';
import 'package:belluga_now/domain/invites/invite_materialize_result.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_next_step.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/invite_share_code_result.dart';
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets('renders deduped inviteables and narrows by relation filter',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = InviteShareScreenController(
      invitesRepository: _FakeInvitesRepository(),
      contactsRepository: _FakeContactsRepository(),
      appData: _buildAppData(),
    );
    GetIt.I.registerSingleton<InviteShareScreenController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(
        home: InviteShareScreen(
          invite: _buildInvite(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Contato'), findsOneWidget);
    expect(find.text('Bia Favorita'), findsOneWidget);

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Contato'), findsNothing);
    expect(find.text('Bia Favorita'), findsOneWidget);

    await tester.tap(find.text('Todos'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Contato'), findsOneWidget);
    expect(find.text('Bia Favorita'), findsOneWidget);
  });

  testWidgets('refresh action refetches the inviteable friends list',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final invitesRepository = _FakeInvitesRepository();
    final controller = InviteShareScreenController(
      invitesRepository: invitesRepository,
      contactsRepository: _FakeContactsRepository(),
      appData: _buildAppData(),
    );
    GetIt.I.registerSingleton<InviteShareScreenController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(
        home: InviteShareScreen(
          invite: _buildInvite(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Contato'), findsOneWidget);
    expect(invitesRepository.fetchInviteableRecipientsCalls, 1);

    invitesRepository.inviteableRecipients = [
      buildInviteableRecipient(
        userId: 'user-3',
        accountProfileId: 'profile-3',
        displayName: 'Caio Amigo',
        profileExposureLevel: 'full_profile',
        inviteableReasons: const <String>['friend'],
      ),
    ];

    await tester.tap(find.text('Atualizar lista de amigos'));
    await tester.pumpAndSettle();

    expect(invitesRepository.fetchInviteableRecipientsCalls, 2);
    expect(find.text('Ana Contato'), findsNothing);
    expect(find.text('Caio Amigo'), findsOneWidget);
  });

  testWidgets('share CTA leaves Gerando state after failure and can retry',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final invitesRepository = _FakeInvitesRepository()
      ..throwOnCreateShareCode = true;
    final controller = InviteShareScreenController(
      invitesRepository: invitesRepository,
      contactsRepository: _FakeContactsRepository(),
      appData: _buildAppData(),
    );
    GetIt.I.registerSingleton<InviteShareScreenController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(
        home: InviteShareScreen(
          invite: _buildInvite(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gerando...'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(invitesRepository.createShareCodeCalls, 1);
    expect(invitesRepository.lastShareCodeOccurrenceId, 'occurrence-1');

    invitesRepository.throwOnCreateShareCode = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(invitesRepository.createShareCodeCalls, 2);
    expect(invitesRepository.lastShareCodeOccurrenceId, 'occurrence-1');
    expect(find.text('Compartilhar'), findsOneWidget);
  });

  testWidgets('renders phone contacts as a separate external-share drill-in',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = InviteShareScreenController(
      invitesRepository: _FakeInvitesRepository(),
      contactsRepository: _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'phone-contact',
            displayName: 'Mae',
            phones: <String>['+55 27 98888-7777'],
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
        home: InviteShareScreen(
          invite: _buildInvite(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Contatos do telefone'), findsOneWidget);
    expect(find.text('1 contato'), findsOneWidget);
    expect(find.text('Mae'), findsNothing);

    await tester.tap(find.text('Contatos do telefone'));
    await tester.pumpAndSettle();

    expect(find.text('Compartilhar externamente'), findsOneWidget);
    expect(find.text('Mae'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Convidar'), findsNWidgets(2));
  });

  testWidgets(
      'external phone contact share launches normalized WhatsApp target',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final launchedUris = <Uri>[];
    final launchedModes = <LaunchMode>[];
    final sharedParams = <ShareParams>[];
    final controller = InviteShareScreenController(
      invitesRepository: _FakeInvitesRepository(),
      contactsRepository: _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'phone-contact',
            displayName: 'Mae',
            phones: <String>['(27) 98888-7777'],
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
        locale: const Locale('pt', 'BR'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationDelegates,
        home: InviteShareScreen(
          invite: _buildInvite(),
          externalUrlLauncher: (uri, {required mode}) async {
            launchedUris.add(uri);
            launchedModes.add(mode);
            return true;
          },
          systemShareLauncher: (params) async {
            sharedParams.add(params);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contatos do telefone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(launchedUris, hasLength(1));
    expect(launchedUris.single.host, 'wa.me');
    expect(launchedUris.single.path, '/5527988887777');
    expect(
      launchedUris.single.queryParameters['text'],
      contains('https://tenant.test/invite?code=SHARE-CODE'),
    );
    expect(launchedModes.single, LaunchMode.externalApplication);
    expect(sharedParams, isEmpty);
  });

  testWidgets('external contact share falls back to system share',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final launchedUris = <Uri>[];
    final sharedParams = <ShareParams>[];
    final controller = InviteShareScreenController(
      invitesRepository: _FakeInvitesRepository(),
      contactsRepository: _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'phone-contact',
            displayName: 'Mae',
            phones: <String>['(27) 98888-7777'],
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
        locale: const Locale('pt', 'BR'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationDelegates,
        home: InviteShareScreen(
          invite: _buildInvite(),
          externalUrlLauncher: (uri, {required mode}) async {
            launchedUris.add(uri);
            return false;
          },
          systemShareLauncher: (params) async {
            sharedParams.add(params);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contatos do telefone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(launchedUris, hasLength(1));
    expect(sharedParams, hasLength(1));
    expect(
      sharedParams.single.text,
      contains('https://tenant.test/invite?code=SHARE-CODE'),
    );
    expect(sharedParams.single.subject, 'Convite Belluga Now');
  });

  testWidgets(
      'external phone contact share does not assume Brazil outside Brazilian locale',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final launchedUris = <Uri>[];
    final sharedParams = <ShareParams>[];
    final controller = InviteShareScreenController(
      invitesRepository: _FakeInvitesRepository(),
      contactsRepository: _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'phone-contact',
            displayName: 'Mae',
            phones: <String>['(27) 98888-7777'],
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
        locale: const Locale('en', 'US'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationDelegates,
        home: InviteShareScreen(
          invite: _buildInvite(),
          externalUrlLauncher: (uri, {required mode}) async {
            launchedUris.add(uri);
            return true;
          },
          systemShareLauncher: (params) async {
            sharedParams.add(params);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Contatos do telefone'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(launchedUris, isEmpty);
    expect(sharedParams, hasLength(1));
    expect(
      sharedParams.single.text,
      contains('https://tenant.test/invite?code=SHARE-CODE'),
    );
  });
}

const _testSupportedLocales = <Locale>[
  Locale('pt', 'BR'),
  Locale('en', 'US'),
];

const _testLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class _FakeContactsRepository implements ContactsRepositoryContract {
  _FakeContactsRepository({
    this.contacts = const <ContactModel>[],
  });

  final List<ContactModel> contacts;

  @override
  final contactsStreamValue =
      StreamValue<List<ContactModel>?>(defaultValue: const <ContactModel>[]);

  @override
  Future<List<ContactModel>> getContacts() async => contacts;

  @override
  Future<void> initializeContacts() async {}

  @override
  Future<void> refreshContacts() async {
    contactsStreamValue.addValue(contacts);
  }

  @override
  Future<bool> requestPermission() async => true;
}

class _FakeInvitesRepository extends InvitesRepositoryContract {
  _FakeInvitesRepository()
      : inviteableRecipients = [
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
            inviteableReasons: const <String>['favorite_by_you'],
          ),
        ];

  bool throwOnCreateShareCode = false;
  int fetchInviteableRecipientsCalls = 0;
  int createShareCodeCalls = 0;
  String? lastShareCodeOccurrenceId;
  List<InviteableRecipient> inviteableRecipients;

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async {
    fetchInviteableRecipientsCalls += 1;
    return inviteableRecipients;
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
          InviteContacts contacts) async =>
      const <InviteContactMatch>[];

  @override
  Future<InviteShareCodeResult> createShareCode({
    required InvitesRepositoryContractPrimString eventId,
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? accountProfileId,
  }) async {
    createShareCodeCalls += 1;
    lastShareCodeOccurrenceId = occurrenceId.value;
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
  Future<List<SentInviteStatus>> getSentInvitesForOccurrence(
    InvitesRepositoryContractPrimString eventId,
  ) async =>
      const <SentInviteStatus>[];

  @override
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {}

  @override
  Future<List<InviteContactGroup>> fetchContactGroups() async =>
      const <InviteContactGroup>[];

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async =>
      const <InviteModel>[];

  @override
  Future<InviteRuntimeSettings> fetchSettings() => throw UnimplementedError();

  @override
  Future<InviteAcceptResult> acceptInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) async =>
      buildInviteAcceptResult(
        inviteId: inviteId.value,
        status: 'accepted',
        creditedAcceptance: true,
        attendancePolicy: 'free_confirmation_only',
        nextStep: InviteNextStep.freeConfirmationCreated,
        supersededInviteIds: const [],
      );

  @override
  Future<InviteDeclineResult> declineInvite(
    InvitesRepositoryContractPrimString inviteId,
  ) =>
      throw UnimplementedError();

  @override
  Future<InviteAcceptResult> acceptInviteByCode(
    InvitesRepositoryContractPrimString code,
  ) =>
      throw UnimplementedError();

  @override
  Future<InviteMaterializeResult> materializeShareCode(
    InvitesRepositoryContractPrimString code,
  ) =>
      throw UnimplementedError();
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
    'profile_types': const [],
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
