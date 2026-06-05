import 'dart:async';

import 'package:belluga_now/application/icons/boora_icons.dart';
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
import 'package:belluga_now/domain/invites/inviteable_reasons.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_hash_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_type_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_profile_exposure_level_value.dart';
import 'package:belluga_now/domain/invites/value_objects/inviteable_reason_value.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/inviteables_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/partners/value_objects/account_profile_type_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile.dart';
import 'package:belluga_now/domain/schedule/event_profile_group.dart';
import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';
import 'package:belluga_now/domain/schedule/sent_invite_summary.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_linked_account_profile_text_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_profile_group_order_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/sent_invite_summary_count_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/slug_value.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_external_contact_share_target.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/invite_share_screen.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_friend_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_summary.dart';
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
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset(dispose: false);
  });

  tearDown(() async {
    await GetIt.I.reset(dispose: false);
  });

  testWidgets('renders inviteables without rejected relation filter chips', (
    tester,
  ) async {
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
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
    );
    await tester.pump();

    expect(find.text('Ana Contato'), findsOneWidget);
    expect(find.text('Bia Favorita'), findsOneWidget);
    expect(find.text('Favoritos'), findsNothing);
    expect(find.text('Todos'), findsNothing);
    expect(find.text('Contatos'), findsNothing);
  });

  testWidgets('agenda refresh appears only on Telefone pane', (
    tester,
  ) async {
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
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
    );
    await tester.pump();

    expect(find.text('Ana Contato'), findsOneWidget);
    expect(find.text('Tenant Test'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(invitesRepository.fetchInviteableRecipientsCalls, 1);
    expect(find.text('Atualizar agenda'), findsNothing);
    expect(find.text('Gerenciar grupos'), findsNothing);
    expect(find.byTooltip('Gerenciar grupos'), findsOneWidget);

    invitesRepository.inviteableRecipients = [
      buildInviteableRecipient(
        userId: 'user-3',
        accountProfileId: 'profile-3',
        displayName: 'Caio Amigo',
        profileExposureLevel: 'full_profile',
        inviteableReasons: const <String>['friend'],
      ),
    ];

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    expect(find.text('Atualizar agenda'), findsOneWidget);
    expect(find.text('Gerenciar grupos'), findsNothing);

    await tester.tap(find.text('Atualizar agenda'));
    await tester.pumpAndSettle();

    expect(invitesRepository.fetchInviteableRecipientsCalls, 3);

    await tester.tap(find.text('Tenant Test'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Contato'), findsNothing);
    expect(find.text('Caio Amigo'), findsOneWidget);
  });

  testWidgets('invite button enters sending state and blocks duplicate taps', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final sendGate = Completer<void>();
    final invitesRepository = _FakeInvitesRepository()
      ..sendInvitesGate = sendGate;
    final controller = InviteShareScreenController(
      invitesRepository: invitesRepository,
      contactsRepository: _FakeContactsRepository(),
      appData: _buildAppData(),
    );
    GetIt.I.registerSingleton<InviteShareScreenController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Convidar').first);
    await tester.pump();

    expect(invitesRepository.sendInvitesCalls, 1);
    expect(find.text('Enviando...'), findsOneWidget);

    await tester.tap(find.text('Enviando...'));
    await tester.pump();

    expect(invitesRepository.sendInvitesCalls, 1);

    sendGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Convidado'), findsOneWidget);
  });

  testWidgets('invite send failure shows feedback and keeps CTA retryable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final invitesRepository = _FakeInvitesRepository()
      ..throwOnSendInvites = true;
    final controller = InviteShareScreenController(
      invitesRepository: invitesRepository,
      contactsRepository: _FakeContactsRepository(),
      appData: _buildAppData(),
    );
    GetIt.I.registerSingleton<InviteShareScreenController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Convidar').first);
    await tester.pumpAndSettle();

    expect(invitesRepository.sendInvitesCalls, 1);
    expect(
      find.text('Não foi possível enviar o convite. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.text('Convidado'), findsNothing);
    expect(find.text('Convidar'), findsWidgets);
  });

  testWidgets(
    'pane segmented button ignores empty and multi-selection payloads',
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
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pump();

      final segmentedButton = tester.widget<SegmentedButton<InviteSharePane>>(
        find.byWidgetPredicate(
          (widget) => widget is SegmentedButton<InviteSharePane>,
        ),
      );

      expect(
        () => segmentedButton.onSelectionChanged?.call(
          <InviteSharePane>{},
        ),
        returnsNormally,
      );
      expect(
        () => segmentedButton.onSelectionChanged?.call(
          <InviteSharePane>{
            InviteSharePane.app,
            InviteSharePane.phone,
          },
        ),
        returnsNormally,
      );

      await tester.pump();

      expect(find.text('Ana Contato'), findsOneWidget);
      expect(find.text('Atualizar agenda'), findsNothing);
    },
  );

  testWidgets('app pane shows loading before empty state resolves', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final invitesRepository = _FakeInvitesRepository()
      ..inviteableRecipients = const <InviteableRecipient>[]
      ..fetchInviteableRecipientsCompleter =
          Completer<List<InviteableRecipient>>();
    final controller = InviteShareScreenController(
      invitesRepository: invitesRepository,
      contactsRepository: _FakeContactsRepository(),
      appData: _buildAppData(),
    );
    GetIt.I.registerSingleton<InviteShareScreenController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
    );
    await tester.pump();

    expect(
      find.text('Nenhuma pessoa do app disponível para convite.'),
      findsNothing,
    );
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    invitesRepository.fetchInviteableRecipientsCompleter!.complete(
      const <InviteableRecipient>[],
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma pessoa do app disponível para convite.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'app pane keeps loading when cache only knows empty imported matches and inviteables are still refreshing',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invitesRepository = _FakeInvitesRepository()
        ..cachedImportContactMatches = const <InviteContactMatch>[]
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ]
        ..fetchInviteableRecipientsCompleter =
            Completer<List<InviteableRecipient>>();
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Cache',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pump();

      expect(
        find.text('Nenhuma pessoa do app disponível para convite.'),
        findsNothing,
      );
      expect(find.text('Ana Contato'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      invitesRepository.fetchInviteableRecipientsCompleter!.complete(
        invitesRepository.inviteableRecipients,
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Contato'), findsOneWidget);
      expect(
        find.text('Nenhuma pessoa do app disponível para convite.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'app pane does not wait for imported contact matches to resolve',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = const <InviteableRecipient>[]
        ..importContactsCompleter = Completer<List<InviteContactMatch>>();
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Match',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pump();

      expect(
        find.text('Nenhuma pessoa do app disponível para convite.'),
        findsOneWidget,
      );
      expect(find.text('Contato Match'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      invitesRepository.importContactsCompleter!.complete(
        <InviteContactMatch>[
          _buildInviteContactMatch(
            userId: 'user-match-1',
            accountProfileId: 'profile-match-1',
            displayName: 'Contato Match',
            contactHash: 'hash-match-1',
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('Contato Match'), findsNothing);
      expect(
        find.text('Nenhuma pessoa do app disponível para convite.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'app pane still renders backend inviteables immediately while imported matches refresh in background',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ]
        ..importContactsCompleter = Completer<List<InviteContactMatch>>();
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Match',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pump();

      expect(find.text('Ana Contato'), findsOneWidget);
      expect(
        find.text('Nenhuma pessoa do app disponível para convite.'),
        findsNothing,
      );

      invitesRepository.importContactsCompleter!.complete(
        const <InviteContactMatch>[],
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('agenda pane shows loading before empty state resolves', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final invitesRepository = _FakeInvitesRepository()
      ..inviteableRecipients = const <InviteableRecipient>[];
    final contactsRepository = _FakeContactsRepository();
    final gate = Completer<List<InviteableRecipient>>();
    invitesRepository.fetchInviteableRecipientsCompleter = gate;
    final controller = InviteShareScreenController(
      invitesRepository: invitesRepository,
      contactsRepository: contactsRepository,
      appData: _buildAppData(),
      isWebRuntime: false,
    );
    GetIt.I.registerSingleton<InviteShareScreenController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
    );
    await tester.pump();

    await tester.tap(find.text('Agenda'));
    await tester.pump();

    expect(find.text('Nenhum contato do telefone disponível.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    gate.complete(const <InviteableRecipient>[]);
    await tester.pumpAndSettle();

    expect(find.text('Nenhum contato do telefone disponível.'), findsOneWidget);
  });

  testWidgets(
    'agenda pane reuses cached phone contacts even when imported matches are still unresolved',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invitesRepository = _FakeInvitesRepository()
        ..fetchInviteableRecipientsCompleter =
            Completer<List<InviteableRecipient>>();
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'phone-contact',
            displayName: 'Mae',
            phones: <String>['+55 27 98888-7777'],
          ),
        ],
      );
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pump();

      await tester.tap(find.text('Agenda'));
      await tester.pump();

      expect(find.text('Mae'), findsOneWidget);
      expect(find.text('Nenhum contato do telefone disponível.'), findsNothing);
    },
  );

  testWidgets(
    'agenda pane keeps loading when permission-granted first load briefly publishes empty targets',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invitesRepository = _FakeInvitesRepository();
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'phone-contact',
            displayName: 'Mae',
            phones: <String>['+55 27 98888-7777'],
          ),
        ],
      )
        ..skipCachedContactsLoad = true
        ..requestPermissionCompleter = Completer<bool>();
      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pump();

      await tester.tap(find.text('Agenda'));
      await tester.pump();

      expect(find.text('Nenhum contato do telefone disponível.'), findsNothing);
      expect(
        controller.isPhonePaneInitialLoadingStreamValue.value,
        isTrue,
      );

      controller.externalContactShareTargetsStreamValue
          .addValue(const <InviteExternalContactShareTarget>[]);
      await tester.pump();

      expect(find.text('Nenhum contato do telefone disponível.'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(
        controller.isPhonePaneInitialLoadingStreamValue.value,
        isTrue,
      );

      contactsRepository.requestPermissionCompleter!.complete(true);
      await tester.pumpAndSettle();

      expect(find.text('Mae'), findsOneWidget);
      expect(find.text('Nenhum contato do telefone disponível.'), findsNothing);
    },
  );

  testWidgets(
    'reopening invite share with repository cache skips loading on app and agenda panes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Cache',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );

      invitesRepository.inviteableRecipientsStreamValue
          .addValue(invitesRepository.inviteableRecipients);
      invitesRepository.importedContactMatchesStreamValue.addValue(
        const <InviteContactMatch>[],
      );
      contactsRepository.contactsStreamValue
          .addValue(contactsRepository.contacts);
      invitesRepository.fetchInviteableRecipientsCompleter =
          Completer<List<InviteableRecipient>>();

      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Ana Contato'), findsOneWidget);

      await tester.tap(find.text('Agenda'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Contato Cache'), findsOneWidget);
    },
  );

  testWidgets(
    'reopening invite share reuses cached app targets from the first live load',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final invitesRepository = _FakeInvitesRepository()
        ..inviteableRecipients = <InviteableRecipient>[
          buildInviteableRecipient(
            userId: 'user-1',
            accountProfileId: 'profile-1',
            displayName: 'Ana Contato',
            inviteableReasons: const <String>['contact_match'],
          ),
        ];
      final contactsRepository = _FakeContactsRepository(
        contacts: <ContactModel>[
          buildContactModel(
            id: 'contact-1',
            displayName: 'Contato Cache',
            phones: <String>['(27) 99999-9999'],
          ),
        ],
      );

      final controller = InviteShareScreenController(
        invitesRepository: invitesRepository,
        contactsRepository: contactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(controller.onDispose);

      await tester.pumpWidget(
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ana Contato'), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();

      invitesRepository.fetchInviteableRecipientsCompleter =
          Completer<List<InviteableRecipient>>();

      await tester.pumpWidget(
        MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
      );
      await tester.pump();

      expect(find.text('Ana Contato'), findsOneWidget);
      expect(
        find.text('Nenhuma pessoa do app disponível para convite.'),
        findsNothing,
      );
    },
  );

  testWidgets('inviteable list builds visible cards lazily', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final invitesRepository = _FakeInvitesRepository()
      ..inviteableRecipients = List<InviteableRecipient>.generate(
        80,
        (index) => buildInviteableRecipient(
          userId: 'user-$index',
          accountProfileId: 'profile-$index',
          displayName: 'Pessoa $index',
          inviteableReasons: const <String>['contact_match'],
        ),
      );
    final controller = InviteShareScreenController(
      invitesRepository: invitesRepository,
      contactsRepository: _FakeContactsRepository(),
      appData: _buildAppData(),
    );
    GetIt.I.registerSingleton<InviteShareScreenController>(controller);
    addTearDown(controller.onDispose);

    await tester.pumpWidget(
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InviteShareFriendCard).evaluate().length, lessThan(80));
    expect(find.text('Pessoa 79'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Pessoa 79'),
      700,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Pessoa 79'), findsOneWidget);
  });

  testWidgets(
    'sent non-null invite status cards disable repeat invite CTA',
    (tester) async {
      var inviteTapCount = 0;
      final pendingFriend = buildInviteableRecipient(
        userId: 'user-pending',
        accountProfileId: 'profile-pending',
        displayName: 'Pessoa Pendente',
      ).toFriendResume();
      final acceptedFriend = buildInviteableRecipient(
        userId: 'user-accepted',
        accountProfileId: 'profile-accepted',
        displayName: 'Pessoa Aceita',
      ).toFriendResume();
      final declinedFriend = buildInviteableRecipient(
        userId: 'user-declined',
        accountProfileId: 'profile-declined',
        displayName: 'Pessoa Recusou',
      ).toFriendResume();
      final supersededFriend = buildInviteableRecipient(
        userId: 'user-superseded',
        accountProfileId: 'profile-superseded',
        displayName: 'Pessoa Confirmada',
      ).toFriendResume();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                InviteShareFriendCard(
                  friend: pendingFriend,
                  status: InviteStatus.pending,
                  onInvite: () => inviteTapCount += 1,
                  isPlaceholder: false,
                  isSending: false,
                ),
                InviteShareFriendCard(
                  friend: acceptedFriend,
                  status: InviteStatus.accepted,
                  onInvite: () => inviteTapCount += 1,
                  isPlaceholder: false,
                  isSending: false,
                ),
                InviteShareFriendCard(
                  friend: declinedFriend,
                  status: InviteStatus.declined,
                  onInvite: () => inviteTapCount += 1,
                  isPlaceholder: false,
                  isSending: false,
                ),
                InviteShareFriendCard(
                  friend: supersededFriend,
                  status: InviteStatus.superseded,
                  onInvite: () => inviteTapCount += 1,
                  isPlaceholder: false,
                  isSending: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Convidado'), findsNWidgets(2));
      expect(find.text('Convite Aceito!'), findsOneWidget);
      expect(find.text('Convite recusado'), findsOneWidget);
      expect(find.text('Confirmado'), findsNothing);
      expect(find.text('Convidar'), findsNothing);

      await tester.tap(find.text('Convidado').first);
      await tester.tap(find.text('Convite Aceito!'));
      await tester.tap(find.text('Convite recusado'));
      await tester.pump();

      expect(inviteTapCount, 0);
    },
  );

  testWidgets(
    'sending invite card disables the CTA while the request is in flight',
    (tester) async {
      var inviteTapCount = 0;
      final friend = buildInviteableRecipient(
        userId: 'user-sending',
        accountProfileId: 'profile-sending',
        displayName: 'Pessoa Enviando',
      ).toFriendResume();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InviteShareFriendCard(
              friend: friend,
              status: null,
              onInvite: () => inviteTapCount += 1,
              isPlaceholder: false,
              isSending: true,
            ),
          ),
        ),
      );

      expect(find.text('Enviando...'), findsOneWidget);
      expect(find.text('Convidar'), findsNothing);

      await tester.tap(find.text('Enviando...'));
      await tester.pump();

      expect(inviteTapCount, 0);
    },
  );

  testWidgets(
    'summary uses exact counters and bounded visible preview',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InviteShareSummary(
              summary: _sentSummary(
                pending: 250,
                accepted: 12,
                preview: <SentInviteStatus>[
                  _sentStatus('profile-pending', InviteStatus.pending),
                  _sentStatus('profile-accepted', InviteStatus.accepted),
                  _sentStatus('profile-superseded', InviteStatus.superseded),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('250 pendentes | 12 aceitos'), findsOneWidget);
      expect(find.text('1 pendentes | 1 aceitos'), findsNothing);
    },
  );

  testWidgets('share CTA leaves Gerando state after failure and can retry', (
    tester,
  ) async {
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
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
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

  testWidgets('renders phone contacts in a separate external-share pane', (
    tester,
  ) async {
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
      MaterialApp(home: InviteShareScreen(invite: _buildInvite())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Mae'), findsNothing);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    expect(find.text('1 contato'), findsOneWidget);
    expect(find.text('Mae'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.byIcon(BooraIcons.whatsapp), findsNWidgets(2));
    expect(find.text('Convidar'), findsNothing);
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

      await tester.tap(find.text('Agenda'));
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
    },
  );

  testWidgets('external contact share falls back to system share', (
    tester,
  ) async {
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
          invite: _buildInviteWithShareContext(),
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

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('WhatsApp'));
    await tester.pumpAndSettle();

    expect(launchedUris, hasLength(1));
    expect(sharedParams, hasLength(1));
    expect(
      sharedParams.single.text,
      contains('https://tenant.test/invite?code=SHARE-CODE'),
    );
    expect(
      sharedParams.single.text,
      startsWith('Amigo te convidou para Evento Teste.'),
    );
    expect(
      sharedParams.single.text,
      contains('Sex, 13 mar · 20h\nGuarapari'),
    );
    expect(sharedParams.single.text, contains('Bandas: Du Jorge, QA Tag'));
    expect(sharedParams.single.text, contains('Responder ao convite:'));
    expect(
      sharedParams.single.text,
      contains('https://tenant.test/invite?code=SHARE-CODE'),
    );
    expect(sharedParams.single.text, isNot(contains('Detalhes:')));
    expect(sharedParams.single.text, isNot(contains('Como chegar:')));
    expect(sharedParams.single.text, isNot(contains('/mapa')));
    expect(sharedParams.single.text, isNot(contains('2026-03-13')));
    expect(sharedParams.single.subject, 'Convite para Evento Teste');
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

      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      expect(launchedUris, isEmpty);
      expect(sharedParams, hasLength(1));
      expect(
        sharedParams.single.text,
        contains('https://tenant.test/invite?code=SHARE-CODE'),
      );
    },
  );

  testWidgets(
    'screen does not overwrite an explicit contact region with locale fallback',
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
        contactRegionCode: 'BR',
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

      expect(controller.debugContactRegionCodeValue, 'BR');

      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      expect(launchedUris, hasLength(1));
      expect(launchedUris.single.host, 'wa.me');
      expect(launchedUris.single.path, '/5527988887777');
      expect(sharedParams, isEmpty);
    },
  );
}

const _testSupportedLocales = <Locale>[Locale('pt', 'BR'), Locale('en', 'US')];

const _testLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class _FakeContactsRepository implements ContactsRepositoryContract {
  _FakeContactsRepository({this.contacts = const <ContactModel>[]});

  final List<ContactModel> contacts;
  bool permissionGranted = true;
  bool skipCachedContactsLoad = false;
  Completer<bool>? requestPermissionCompleter;

  @override
  final contactsStreamValue =
      StreamValue<List<ContactModel>?>(defaultValue: null);

  @override
  Future<List<ContactModel>> getContacts() async => contacts;

  @override
  Future<void> initializeContacts() async {}

  @override
  Future<void> loadCachedContacts() async {
    if (skipCachedContactsLoad) {
      return;
    }
    if (contacts.isNotEmpty) {
      contactsStreamValue.addValue(contacts);
    }
  }

  @override
  Future<void> refreshCachedContacts() async {
    contactsStreamValue.addValue(contacts);
  }

  @override
  Future<void> refreshContacts() async {
    contactsStreamValue.addValue(contacts);
  }

  @override
  Future<bool> requestPermission() async {
    final completer = requestPermissionCompleter;
    if (completer != null) {
      return completer.future;
    }
    return permissionGranted;
  }
}

class _FakeInvitesRepository extends InvitesRepositoryContract
    implements InviteablesRepositoryContract {
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
  bool throwOnSentSummary = false;
  bool throwOnSendInvites = false;
  bool acknowledgeSendInvites = true;
  int fetchInviteableRecipientsCalls = 0;
  int createShareCodeCalls = 0;
  int sendInvitesCalls = 0;
  String? lastShareCodeOccurrenceId;
  List<InviteableRecipient> inviteableRecipients;
  List<InviteContactMatch>? cachedImportContactMatches;
  Completer<List<InviteContactMatch>>? importContactsCompleter;
  List<InviteContactMatch> importContactMatches = const <InviteContactMatch>[];
  Completer<List<InviteableRecipient>>? fetchInviteableRecipientsCompleter;
  Completer<void>? sendInvitesGate;

  @override
  final inviteableRecipientsStreamValue =
      StreamValue<List<InviteableRecipient>?>(defaultValue: null);

  @override
  Future<List<InviteableRecipient>> fetchInviteableRecipients() async {
    fetchInviteableRecipientsCalls += 1;
    if (fetchInviteableRecipientsCompleter != null) {
      final recipients = await fetchInviteableRecipientsCompleter!.future;
      inviteableRecipientsStreamValue.addValue(recipients);
      return recipients;
    }
    inviteableRecipientsStreamValue.addValue(inviteableRecipients);
    return inviteableRecipients;
  }

  @override
  Future<void> refreshInviteableRecipients() async {
    final recipients = await fetchInviteableRecipients();
    inviteableRecipientsStreamValue.addValue(recipients);
  }

  @override
  Future<List<InviteContactMatch>> importContacts(
    InviteContacts contacts,
  ) async {
    if (importContactsCompleter != null) {
      return importContactsCompleter!.future;
    }
    return importContactMatches;
  }

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
  Future<void> sendInvites(
    InvitesRepositoryContractPrimString eventId,
    InviteRecipients recipients, {
    InvitesRepositoryContractPrimString? occurrenceId,
    InvitesRepositoryContractPrimString? message,
  }) async {
    sendInvitesCalls += 1;
    await sendInvitesGate?.future;
    if (throwOnSendInvites) {
      throw Exception('send failed');
    }
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
      occurrenceId?.value ?? 'occurrence-1',
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
  Future<SentInviteSummary> refreshSentInviteSummaryForOccurrence({
    required InvitesRepositoryContractPrimString occurrenceId,
    InvitesRepositoryContractPrimString? eventId,
    InvitesRepositoryContractPrimInt? previewLimit,
  }) async {
    if (throwOnSentSummary) {
      throw Exception('sent summary failed');
    }
    return SentInviteSummary.empty();
  }

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

InviteModel _buildInviteWithShareContext() {
  final duJorge = _buildLinkedAccountProfile(
    id: 'profile-du-jorge',
    displayName: 'Du Jorge',
    profileType: 'band',
  );
  final qaTag = _buildLinkedAccountProfile(
    id: 'profile-qa-tag',
    displayName: 'QA Tag',
    profileType: 'artist',
  );
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
    linkedAccountProfiles: [duJorge, qaTag],
    profileGroups: [
      EventProfileGroup(
        idValue: EventLinkedAccountProfileTextValue('group-bandas'),
        labelValue: EventLinkedAccountProfileTextValue('Bandas'),
        orderValue: EventProfileGroupOrderValue()..parse('0'),
        profiles: [duJorge, qaTag],
      ),
    ],
    venueAccountProfileId: 'venue-1',
  );
}

EventLinkedAccountProfile _buildLinkedAccountProfile({
  required String id,
  required String displayName,
  required String profileType,
}) {
  return EventLinkedAccountProfile(
    idValue: EventLinkedAccountProfileTextValue(id),
    displayNameValue: EventLinkedAccountProfileTextValue(displayName),
    profileTypeValue: AccountProfileTypeValue(profileType),
    slugValue: SlugValue()..parse(id),
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

InviteContactMatch _buildInviteContactMatch({
  required String userId,
  required String accountProfileId,
  required String displayName,
  required String contactHash,
}) {
  return InviteContactMatch(
    contactHashValue: InviteContactHashValue()..parse(contactHash),
    typeValue: InviteContactTypeValue()..parse('phone'),
    userIdValue: UserIdValue()..parse(userId),
    receiverAccountProfileIdValue: InviteAccountProfileIdValue()
      ..parse(accountProfileId),
    displayNameValue: InviteInviterNameValue()..parse(displayName),
    profileExposureLevelValue: InviteProfileExposureLevelValue()
      ..parse('capped_profile'),
    inviteableReasons: InviteableReasons([
      InviteableReasonValue()..parse('contact_match'),
    ]),
    isInviteableValue: DomainBooleanValue()..parse('true'),
  );
}

SentInviteStatus _sentStatus(String accountProfileId, InviteStatus status) {
  return SentInviteStatus(
    friend: EventFriendResume(
      idValue: UserIdValue()..parse('user-$accountProfileId'),
      accountProfileIdValue: InviteAccountProfileIdValue()
        ..parse(accountProfileId),
      displayNameValue: UserDisplayNameValue()..parse(accountProfileId),
      avatarUrlValue: UserAvatarValue(),
    ),
    status: status,
    sentAtValue: DateTimeValue()..parse('2026-05-23T12:00:00Z'),
  );
}

SentInviteStatus _pendingSentStatus(EventFriendResume recipient) {
  return SentInviteStatus(
    friend: recipient,
    status: InviteStatus.pending,
    sentAtValue: DateTimeValue()..parse('2026-05-23T12:00:00Z'),
  );
}

SentInviteSummary _sentSummary({
  required int pending,
  required int accepted,
  List<SentInviteStatus> preview = const <SentInviteStatus>[],
}) {
  return SentInviteSummary(
    pendingValue: SentInviteSummaryCountValue()..parse(pending.toString()),
    acceptedValue: SentInviteSummaryCountValue()..parse(accepted.toString()),
    declinedValue: SentInviteSummaryCountValue(),
    terminalHiddenValue: SentInviteSummaryCountValue(),
    totalVisibleValue: SentInviteSummaryCountValue()
      ..parse((pending + accepted).toString()),
    totalSentValue: SentInviteSummaryCountValue()
      ..parse((pending + accepted).toString()),
    preview: preview,
  );
}
