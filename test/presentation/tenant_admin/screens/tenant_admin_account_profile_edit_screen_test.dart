import 'package:belluga_contact_channels/belluga_contact_channels.dart';
import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_external_image_proxy_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_candidate_selection_summary.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_snapshot.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_label_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_head_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_group_members_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousHttpOverrides;

  setUpAll(() {
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _TestHttpOverrides();
  });

  setUp(() async {
    await GetIt.I.reset();

    final accountsRepository = _FakeAccountsRepository();
    final profilesRepository = _FakeAccountProfilesRepository();
    final taxonomiesRepository = _FakeTaxonomiesRepository();
    final TenantAdminLocationSelectionContract locationSelectionService =
        TenantAdminLocationSelectionService();

    GetIt.I.registerSingleton<TenantAdminAccountsRepositoryContract>(
      accountsRepository,
    );
    GetIt.I.registerSingleton<TenantAdminAccountProfilesRepositoryContract>(
      profilesRepository,
    );
    GetIt.I.registerSingleton<TenantAdminTaxonomiesRepositoryContract>(
      taxonomiesRepository,
    );
    GetIt.I.registerSingleton<TenantAdminLocationSelectionContract>(
      locationSelectionService,
    );
    GetIt.I.registerSingleton<TenantAdminExternalImageProxyContract>(
      _FakeExternalImageProxy(),
    );
    GetIt.I.registerSingleton<TenantAdminImageIngestionService>(
      TenantAdminImageIngestionService(),
    );

    final controller = TenantAdminAccountProfilesController(
      profilesRepository: profilesRepository,
      accountsRepository: accountsRepository,
      taxonomiesRepository: taxonomiesRepository,
      locationSelectionService: locationSelectionService,
    );

    // Simulate stale singleton controller state from a previous edit session.
    controller.accountProfileStreamValue.addValue(
      _profile(id: 'stale-profile'),
    );

    GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(controller);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  tearDownAll(() {
    HttpOverrides.global = previousHttpOverrides;
  });

  testWidgets(
    'prefers route profile id over cached controller profile id on init',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      expect(profilesRepository.fetchAccountProfileCalls, 1);
      expect(profilesRepository.lastFetchedProfileId, 'route-profile');
    },
  );

  testWidgets(
    'blocks update when display name has fewer than three characters',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final controller = GetIt.I.get<TenantAdminAccountProfilesController>();
      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.controller == controller.displayNameController,
      );
      await tester.enterText(nameField, 'An');
      await tester.scrollUntilVisible(
        find.text('Salvar alteracoes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pump();

      expect(
        find.text('Nome de exibicao deve ter pelo menos 3 caracteres.'),
        findsOneWidget,
      );
      expect(profilesRepository.updateAccountProfileCalls, 0);
    },
  );

  testWidgets('submits a three-character display name update', (tester) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;

    await _pumpScreen(
      tester,
      TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    final controller = GetIt.I.get<TenantAdminAccountProfilesController>();
    final nameField = find.byWidgetPredicate(
      (widget) =>
          widget is TextFormField &&
          widget.controller == controller.displayNameController,
    );
    await tester.enterText(nameField, 'Ane');
    await tester.scrollUntilVisible(
      find.text('Salvar alteracoes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Salvar alteracoes'));
    await tester.pumpAndSettle();

    expect(profilesRepository.updateAccountProfileCalls, 1);
    expect(profilesRepository.lastUpdatedDisplayName, 'Ane');
  });

  testWidgets(
    'hydrates from the route-resolved profile without a duplicate fetch',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      final resolvedProfile = _profile(
        id: 'route-profile',
        displayName: 'Perfil resolvido',
      );

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
          initialProfile: resolvedProfile,
        ),
      );

      expect(profilesRepository.fetchAccountProfileCalls, 0);
      expect(find.text('Perfil resolvido'), findsOneWidget);
    },
  );

  testWidgets('renders the production-shaped AGLA payload in the edit route', (
    tester,
  ) async {
    final profile = TenantAdminAccountProfileDTO.fromJson({
      'id': '6a6bc34e512136a0050eabaa',
      'account_id': '6a6bc34e512136a0050eaba8',
      'profile_type': 'associacao',
      'display_name': 'AGLA',
      'slug': 'agla',
      'aggregate_revision': 1,
      'contact_mode': 'own',
      'contact_channels': const [],
      'effective_contact_channels': const [],
      'effective_contact_source': {
        'id': '6a6bc34e512136a0050eabaa',
        'display_name': 'AGLA',
        'profile_type': 'associacao',
        'slug': 'agla',
      },
    }).toDomain();

    await _pumpScreen(
      tester,
      TenantAdminAccountProfileEditScreen(
        accountSlug: 'agla',
        accountProfileId: profile.id,
        initialProfile: profile,
      ),
    );

    final controller = GetIt.I.get<TenantAdminAccountProfilesController>();
    expect(controller.displayNameController.text, 'AGLA');
    expect(find.text('Salvar alteracoes'), findsOneWidget);
  });

  testWidgets(
    'renders persisted avatar and cover URLs as network images in edit form',
    (tester) async {
      const avatarUrl =
          'https://tenant-a.test/media/account-profiles/avatar.png';
      const coverUrl = 'https://tenant-a.test/media/account-profiles/cover.png';
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        avatarUrl: avatarUrl,
        coverUrl: coverUrl,
      );

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final avatarImageFinder = find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final provider = widget.image;
        return provider is NetworkImage && provider.url == avatarUrl;
      });
      final coverImageFinder = find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final provider = widget.image;
        return provider is NetworkImage && provider.url == coverUrl;
      });

      expect(avatarImageFinder, findsOneWidget);
      expect(coverImageFinder, findsOneWidget);
    },
  );

  testWidgets('renders ownership management selector in edit form', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    expect(find.text('Gestao da conta'), findsOneWidget);
    expect(find.text('Do tenant'), findsOneWidget);
  });

  testWidgets(
    'keeps the profile type selector within a narrow edit form for long labels',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(
          hasGallery: false,
          hasNestedProfileGroups: false,
          type: 'poi',
          label: 'POI',
        ),
        _profileType(
          hasGallery: false,
          hasNestedProfileGroups: false,
          type: 'long-label',
          label: 'Tipo de perfil com um rotulo muito longo para o celular',
        ),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        profileType: 'poi',
      );

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final profileTypeDropdown = find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == 'Tipo de perfil',
      );
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        profileTypeDropdown,
      );
      final innerDropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: profileTypeDropdown,
          matching: find.byType(DropdownButton<String>),
        ),
      );

      expect(dropdown.decoration.labelText, 'Tipo de perfil');
      expect(innerDropdown.isExpanded, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders display name field in edit form', (tester) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository.profileToReturn = _profile(
      id: 'route-profile',
      displayName: 'Conta Parceira',
    );

    await _pumpScreen(
      tester,
      TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Nome de exibicao'),
      200,
      scrollable: scrollable,
    );

    expect(find.text('Nome de exibicao'), findsOneWidget);
    expect(find.text('Conta Parceira'), findsOneWidget);
  });

  testWidgets(
    'renders mirrored contact preview without deprecated global bubble or CTA sections',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      final whatsappChannel = BellugaContactChannel(
        id: 'whatsapp-primary',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-9999',
        title: 'Atendimento',
        initialMessages: const [
          BellugaContactInitialMessage(
            id: 'wa-cta-1',
            cta: 'Quero falar',
            message: 'Quero falar sobre o perfil.',
          ),
        ],
      );
      final sourceProfile = _profile(
        id: '507f1f77bcf86cd799439099',
        displayName: 'Perfil Fonte',
        contactChannels: [whatsappChannel],
        effectiveContactChannels: [whatsappChannel],
        contactBubbleChannelId: whatsappChannel.id,
      );
      profilesRepository.profileTypesToReturn = [
        _profileType(
          hasGallery: false,
          hasNestedProfileGroups: false,
          hasContactChannels: true,
        ),
      ];
      profilesRepository.profilesToReturn = [sourceProfile];
      profilesRepository.accountProfileFetchOverrides[sourceProfile.id] =
          sourceProfile;
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        contactMode: BellugaContactSourceMode.mirroredAccountProfile,
        contactSourceAccountProfileId: sourceProfile.id,
        contactBubbleChannelId: whatsappChannel.id,
        effectiveContactChannels: [whatsappChannel],
      );

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Origem do Contato'),
        300,
        scrollable: scrollable,
      );

      expect(find.text('Origem do Contato'), findsOneWidget);
      expect(find.text('Canais de Contato'), findsOneWidget);
      expect(find.text('Balão Flutuante'), findsNothing);
      expect(find.text('CTA e Mensagens do WhatsApp'), findsNothing);
      expect(
        find.byKey(const Key('tenantAdminEditContactSourcePicker')),
        findsOneWidget,
      );
      expect(find.textContaining('Perfil Fonte'), findsWidgets);
      expect(find.text('WhatsApp'), findsWidgets);
      expect(find.text('+55 (27) 99999-9999 • Atendimento'), findsWidgets);
    },
  );

  testWidgets(
    'renders the source bubble selection as an inert mirrored indicator',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      final sourceChannel = BellugaContactChannel(
        id: 'source-whatsapp',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-9999',
      );
      final sourceProfile = _profile(
        id: '507f1f77bcf86cd799439001',
        contactChannels: [sourceChannel],
        effectiveContactChannels: [sourceChannel],
        contactBubbleChannelId: sourceChannel.id,
      );
      profilesRepository.profileTypesToReturn = [
        _profileType(
          hasGallery: false,
          hasNestedProfileGroups: false,
          hasContactChannels: true,
        ),
      ];
      profilesRepository.profilesToReturn = [sourceProfile];
      profilesRepository.accountProfileFetchOverrides[sourceProfile.id] =
          sourceProfile;
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        contactMode: BellugaContactSourceMode.mirroredAccountProfile,
        contactSourceAccountProfileId: sourceProfile.id,
      );

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final toggle = find
          .byKey(
            const Key('tenantAdminEditMirroredBubbleToggle_source-whatsapp'),
          )
          .last;
      await tester.ensureVisible(toggle);

      final switchListTile = tester.widget<SwitchListTile>(toggle);
      expect(switchListTile.value, isTrue);
      expect(switchListTile.onChanged, isNull);

      final bubbleSelectionBefore = GetIt.I
          .get<TenantAdminAccountProfilesController>()
          .editStateStreamValue
          .value
          .contactBubbleSelection;

      await tester.tap(toggle);
      await tester.pump();
      await tester.tap(
        find.descendant(of: toggle, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(
        GetIt.I
            .get<TenantAdminAccountProfilesController>()
            .editStateStreamValue
            .value
            .contactBubbleSelection,
        same(bubbleSelectionBefore),
      );
    },
  );

  testWidgets('renders a mirrored source without a bubble selection as off', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    final sourceChannel = BellugaContactChannel(
      id: 'source-whatsapp-off',
      type: BellugaContactChannelType.whatsapp,
      value: '+55 (27) 98888-7777',
    );
    final sourceProfile = _profile(
      id: '507f1f77bcf86cd799439002',
      contactChannels: [sourceChannel],
      effectiveContactChannels: [sourceChannel],
    );
    profilesRepository.profileTypesToReturn = [
      _profileType(
        hasGallery: false,
        hasNestedProfileGroups: false,
        hasContactChannels: true,
      ),
    ];
    profilesRepository.profilesToReturn = [sourceProfile];
    profilesRepository.accountProfileFetchOverrides[sourceProfile.id] =
        sourceProfile;
    profilesRepository.profileToReturn = _profile(
      id: 'route-profile',
      contactMode: BellugaContactSourceMode.mirroredAccountProfile,
      contactSourceAccountProfileId: sourceProfile.id,
      contactBubbleChannelId: sourceChannel.id,
    );

    await _pumpScreen(
      tester,
      const TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    final toggle = find
        .byKey(
          const Key('tenantAdminEditMirroredBubbleToggle_source-whatsapp-off'),
        )
        .last;
    await tester.ensureVisible(toggle);

    final switchListTile = tester.widget<SwitchListTile>(toggle);
    expect(switchListTile.value, isFalse);
    expect(switchListTile.onChanged, isNull);
  });

  testWidgets('keeps own contact bubble selection interactive', (tester) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    final ownChannel = BellugaContactChannel(
      id: 'own-whatsapp',
      type: BellugaContactChannelType.whatsapp,
      value: '+55 (27) 97777-6666',
    );
    profilesRepository.profileTypesToReturn = [
      _profileType(
        hasGallery: false,
        hasNestedProfileGroups: false,
        hasContactChannels: true,
      ),
    ];
    profilesRepository.profileToReturn = _profile(
      id: 'route-profile',
      contactChannels: [ownChannel],
      effectiveContactChannels: [ownChannel],
    );

    await _pumpScreen(
      tester,
      const TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    final draftKey = GetIt.I
        .get<TenantAdminAccountProfilesController>()
        .editStateStreamValue
        .value
        .contactChannelDrafts
        .single
        .draftKey;
    final toggle = find.byKey(Key('tenantAdminContactBubbleToggle_$draftKey'));
    await tester.scrollUntilVisible(
      toggle,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(toggle);
    await tester.pump();

    expect(
      GetIt.I
          .get<TenantAdminAccountProfilesController>()
          .editStateStreamValue
          .value
          .contactBubbleSelection,
      isA<BellugaContactBubbleSelectionPersisted>().having(
        (selection) => selection.channelId,
        'channelId',
        ownChannel.id,
      ),
    );
  });

  testWidgets(
    'opens the mirrored contact source picker with server candidates and no crash fallback',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      final sourceProfile = _profile(
        id: '507f1f77bcf86cd7994390aa',
        displayName: 'Perfil Fonte Picker',
        profileType: 'venue',
      );
      profilesRepository.profileTypesToReturn = [
        _profileType(
          hasGallery: false,
          hasNestedProfileGroups: false,
          hasContactChannels: true,
        ),
      ];
      profilesRepository.profilesToReturn = [sourceProfile];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        contactMode: BellugaContactSourceMode.mirroredAccountProfile,
      );

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminEditContactSourcePicker')),
        300,
        scrollable: scrollable,
      );
      await tester.tap(
        find.byKey(const Key('tenantAdminEditContactSourcePicker')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perfil de origem'), findsOneWidget);
      expect(
        find.byKey(const Key('tenantAdminAccountProfilePickerList')),
        findsOneWidget,
      );
      expect(find.text('Perfil Fonte Picker'), findsOneWidget);
      expect(find.text('venue'), findsOneWidget);
      expect(
        find.text('Nenhum perfil elegível para espelhar contatos.'),
        findsNothing,
      );
      expect(find.textContaining("Instance of 'minified"), findsNothing);
      expect(find.textContaining("Instance of '"), findsNothing);
    },
  );

  testWidgets(
    'keeps the mirrored contact source picker stable on a narrow viewport when the keyboard opens',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);

      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      final sourceProfile = _profile(
        id: '507f1f77bcf86cd7994390ab',
        displayName: 'Perfil Fonte Estavel',
        profileType: 'venue',
      );
      profilesRepository.profileTypesToReturn = [
        _profileType(
          hasGallery: false,
          hasNestedProfileGroups: false,
          hasContactChannels: true,
        ),
      ];
      profilesRepository.profilesToReturn = [sourceProfile];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        contactMode: BellugaContactSourceMode.mirroredAccountProfile,
      );

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      final pickerButton = find.byKey(
        const Key('tenantAdminEditContactSourcePicker'),
      );
      await tester.scrollUntilVisible(
        pickerButton,
        300,
        scrollable: scrollable,
      );
      await tester.tap(pickerButton);
      await tester.pumpAndSettle();

      final searchField = find.byKey(
        const Key('tenantAdminAccountProfilePickerSearchField'),
      );
      expect(searchField, findsOneWidget);

      await tester.tap(searchField);
      await tester.pump();

      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(searchField, findsOneWidget);
      expect(
        find.byKey(const Key('tenantAdminAccountProfilePickerList')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hydrates the persisted mirrored contact source when it is outside the first candidate page',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      final whatsappChannel = BellugaContactChannel(
        id: 'whatsapp-hydrated',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 98888-7777',
        title: 'Canal hidratado',
      );
      final sourceProfile = _profile(
        id: '507f1f77bcf86cd799439051',
        displayName: 'Perfil Fonte 51',
        contactChannels: [whatsappChannel],
        effectiveContactChannels: [whatsappChannel],
        contactBubbleChannelId: whatsappChannel.id,
      );
      profilesRepository.profileTypesToReturn = [
        _profileType(
          hasGallery: false,
          hasNestedProfileGroups: false,
          hasContactChannels: true,
        ),
      ];
      profilesRepository.profilesToReturn = List<TenantAdminAccountProfile>.of([
        for (var index = 0; index < 50; index++)
          _profile(
            id: 'profile-candidate-$index',
            displayName: 'Candidate $index',
          ),
        sourceProfile,
      ]);
      profilesRepository.accountProfileFetchOverrides[sourceProfile.id] =
          sourceProfile;
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        contactMode: BellugaContactSourceMode.mirroredAccountProfile,
        contactSourceAccountProfileId: sourceProfile.id,
        contactBubbleChannelId: whatsappChannel.id,
      );

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Origem do Contato'),
        300,
        scrollable: scrollable,
      );

      expect(find.textContaining('Perfil Fonte 51'), findsWidgets);
      expect(find.textContaining('Canal hidratado'), findsWidgets);
    },
  );

  testWidgets(
    'shows persisted WhatsApp CTAs from the channel when editing an own profile',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      final whatsappChannel = BellugaContactChannel(
        id: 'whatsapp-ananda',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-1111',
        initialMessages: const [
          BellugaContactInitialMessage(
            id: 'whatsapp-ananda-cta-1',
            cta: 'Falar com a Ananda',
            message: 'Olá, gostaria de saber mais.',
          ),
        ],
      );
      profilesRepository.profileTypesToReturn = [
        _profileType(
          hasGallery: false,
          hasNestedProfileGroups: false,
          hasContactChannels: true,
        ),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'profile-ananda',
        displayName: 'Ananda',
        contactChannels: [whatsappChannel],
        effectiveContactChannels: [whatsappChannel],
        contactBubbleChannelId: whatsappChannel.id,
      );

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'profile-ananda',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Falar com a Ananda'),
        300,
        scrollable: scrollable,
      );

      expect(find.text('CTAs e mensagens'), findsOneWidget);
      expect(find.text('Falar com a Ananda'), findsOneWidget);
      expect(
        find.byKey(
          const Key(
            'tenantAdminContactCta_persisted:whatsapp-ananda_whatsapp-ananda-cta-1',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('renders persisted gallery groups and descriptions', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository.profileTypesToReturn = [
      _profileType(hasGallery: true, hasNestedProfileGroups: false),
    ];
    profilesRepository.profileToReturn = _profile(
      id: 'route-profile',
      galleryGroups: [_galleryGroup()],
      galleryCapabilities: TenantAdminAccountProfileGalleryCapabilities(
        maxGalleriesValue: TenantAdminCountValue(0),
        maxItemsPerGalleryValue: TenantAdminCountValue(0),
      ),
    );

    await _pumpScreen(
      tester,
      TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Galerias'),
      200,
      scrollable: scrollable,
    );

    expect(find.text('Galerias'), findsOneWidget);
    expect(
      find.byKey(const Key('tenantAdminGalleryGroup_group-1')),
      findsOneWidget,
    );
    expect(find.text('Ambiente'), findsOneWidget);
    expect(find.text('Vista para o palco'), findsOneWidget);
    expect(find.textContaining('Remova pelo menos 1 galeria'), findsOneWidget);
    expect(find.textContaining('Remova pelo menos 1 item'), findsOneWidget);
  });

  testWidgets(
    'gallery title failure keeps entered text and retries once from confirmed state',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: true, hasNestedProfileGroups: false),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        galleryGroups: [_galleryGroup(title: 'Título confirmado')],
      );
      profilesRepository.gallerySnapshotToReturn =
          TenantAdminAccountProfileGallerySnapshot(
            groups: [_galleryGroup(title: 'Título canônico')],
            capabilities: TenantAdminAccountProfileGalleryCapabilities(
              maxGalleriesValue: TenantAdminCountValue(6),
              maxItemsPerGalleryValue: TenantAdminCountValue(12),
            ),
          );
      profilesRepository.updateGalleryItemError = FormValidationFailure(
        statusCode: 422,
        message: 'Falha persistente ao atualizar o título.',
        fieldErrors: const {
          'global': ['O item mudou no servidor.'],
        },
      );

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final titleField = find.byKey(
        const Key('tenantAdminGalleryItemTitle_item-1'),
      );
      await tester.scrollUntilVisible(
        titleField,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(titleField, 'Título corrigido');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();

      expect(profilesRepository.updateGalleryItemCalls, 1);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: titleField,
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Título corrigido',
      );
      expect(
        GetIt.I
            .get<TenantAdminAccountProfilesController>()
            .editStateStreamValue
            .value
            .galleryGroups
            .single
            .items
            .single
            .title,
        'Título confirmado',
      );
      expect(
        find.textContaining('Falha persistente ao atualizar o título.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('tenantAdminGalleryOperationError')),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);

      profilesRepository.updateGalleryItemError = null;
      await tester.tap(titleField);
      await tester.enterText(titleField, 'Título corrigido');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(profilesRepository.updateGalleryItemCalls, 2);
      expect(
        GetIt.I
            .get<TenantAdminAccountProfilesController>()
            .editStateStreamValue
            .value
            .galleryGroups
            .single
            .items
            .single
            .title,
        'Título canônico',
      );
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: titleField,
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Título canônico',
      );
      expect(
        find.byKey(const Key('tenantAdminGalleryOperationError')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'hides gallery editor and omits gallery payload when capability is disabled',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: false, hasNestedProfileGroups: false),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        galleryGroups: [_galleryGroup()],
      );

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      expect(find.text('Galerias de fotos'), findsNothing);
      expect(
        find.byKey(const Key('tenantAdminGalleryGroup_group-1')),
        findsNothing,
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Salvar alteracoes'),
        200,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'hides nested group editor and omits nested payload when capability is disabled',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: false, hasNestedProfileGroups: false),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        nestedProfileGroups: [_nestedGroup()],
      );

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      expect(find.text('Abas de contas vinculadas'), findsNothing);
      expect(
        find.byKey(const Key('tenantAdminEditAddNestedGroupButton')),
        findsNothing,
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Salvar alteracoes'),
        200,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pumpAndSettle();

      expect(profilesRepository.lastNestedProfileGroups, isNull);
    },
  );

  testWidgets('renders nested group summary when capability is enabled', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository.profileTypesToReturn = [
      _profileType(hasGallery: false, hasNestedProfileGroups: true),
    ];
    profilesRepository.profileToReturn = _profile(
      id: 'route-profile',
      nestedProfileGroups: [_nestedGroupMetadataOnly(memberCount: 1)],
    );
    await _pumpScreen(
      tester,
      TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Abas de contas vinculadas'),
      200,
      scrollable: scrollable,
    );

    expect(find.text('Abas de contas vinculadas'), findsOneWidget);
    expect(find.text('Parceiros'), findsWidgets);
    expect(find.text('1 perfil vinculado'), findsOneWidget);
    expect(find.text('Gerenciar perfis'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('tenantAdminEditProfileGroupLabel_partners')),
    );
    await tester.pump();
    expect(
      find.byKey(const Key('tenantAdminEditProfileGroupLabelInput_partners')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('tenantAdminEditProfileGroupLabelInput_partners')),
      'Parceiros do servidor',
    );
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    expect(profilesRepository.lastPatchNestedGroupProfileId, 'route-profile');
    expect(profilesRepository.lastPatchNestedGroupId, 'partners');
    expect(find.text('Parceiros autoritativos'), findsOneWidget);
  });

  testWidgets(
    'saving edit profile does not hydrate or submit nested groups in aggregate save',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: false, hasNestedProfileGroups: true),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        nestedProfileGroups: [_nestedGroupMetadataOnly(memberCount: 3)],
      );
      profilesRepository.nestedGroupMemberPagesByGroupId['partners'] = [
        TenantAdminNestedGroupMemberPage(
          items: <TenantAdminAccountProfileSelectionSummary>[
            TenantAdminAccountProfileSelectionSummary(
              idValue: TenantAdminAccountProfileIdValue('profile-a'),
              displayNameValue: TenantAdminOptionalTextValue(
                defaultValue: 'Profile A',
              ),
            ),
          ],
          nextCursorValue: TenantAdminOptionalTextValue(
            defaultValue: 'cursor-2',
          ),
        ),
        TenantAdminNestedGroupMemberPage(
          items: <TenantAdminAccountProfileSelectionSummary>[
            TenantAdminAccountProfileSelectionSummary(
              idValue: TenantAdminAccountProfileIdValue('profile-b'),
              displayNameValue: TenantAdminOptionalTextValue(
                defaultValue: 'Profile B',
              ),
            ),
            TenantAdminAccountProfileSelectionSummary(
              idValue: TenantAdminAccountProfileIdValue('profile-c'),
              displayNameValue: TenantAdminOptionalTextValue(
                defaultValue: 'Profile C',
              ),
            ),
          ],
          nextCursorValue: TenantAdminOptionalTextValue(),
        ),
      ];

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Salvar alteracoes'),
        200,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pumpAndSettle();

      expect(profilesRepository.fetchAllNestedGroupMembersCalls, 0);
      expect(profilesRepository.lastNestedProfileGroups, isNull);
    },
  );

  testWidgets(
    'manage-group picker reloads candidates and excludes the current profile',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: false, hasNestedProfileGroups: true),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        nestedProfileGroups: [
          TenantAdminNestedProfileGroup(
            idValue: TenantAdminNestedProfileGroupTextValue('partners'),
            labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
            orderValue: TenantAdminNestedProfileGroupOrderValue(0),
            accountProfileIdValues: const [],
          ),
        ],
      );
      profilesRepository.pagedProfilesToReturnByRequest = [
        [
          _profile(
            id: 'route-profile',
            displayName: 'Perfil atual',
            profileType: 'poi',
          ),
          _profile(
            id: 'profile-partner',
            displayName: 'Conta Parceira',
            profileType: 'poi',
          ),
        ],
      ];

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Abas de contas vinculadas'),
        200,
        scrollable: scrollable,
      );
      final baselineFetchCalls =
          profilesRepository.fetchAccountProfilesPageCalls;
      await tester.tap(
        find.byKey(const Key('tenantAdminEditManageGroup_partners')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Adicionar perfis'));
      await tester.pumpAndSettle();

      expect(find.text('Conta Parceira'), findsOneWidget);
      expect(find.text('Perfil atual'), findsNothing);
      expect(
        profilesRepository.fetchAccountProfilesPageCalls,
        baselineFetchCalls + 1,
      );
    },
  );

  testWidgets('manage-group multi picker stays stable on a narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository.profileTypesToReturn = [
      _profileType(hasGallery: false, hasNestedProfileGroups: true),
    ];
    profilesRepository.profileToReturn = _profile(
      id: 'route-profile',
      nestedProfileGroups: [_nestedGroupMetadataOnly(memberCount: 0)],
    );
    profilesRepository.nestedGroupMemberPagesByGroupId['partners'] =
        <TenantAdminNestedGroupMemberPage>[
          _nestedGroupMemberPage(items: const <Map<String, Object?>>[]),
        ];
    profilesRepository.pagedProfilesToReturnByRequest = [
      [
        _profile(
          id: 'route-profile',
          displayName: 'Perfil atual',
          profileType: 'poi',
        ),
        _profile(
          id: 'profile-partner',
          displayName:
              'Conta Parceira com nome suficientemente grande para pressionar o layout do picker',
          profileType: 'poi',
        ),
      ],
    ];

    await _pumpScreen(
      tester,
      const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      ),
    );

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('tenantAdminEditManageGroup_partners')),
      200,
      scrollable: scrollable,
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminEditManageGroup_partners')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Adicionar perfis'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('tenantAdminAccountProfilePickerSearchField')),
      findsOneWidget,
    );
    expect(find.textContaining('Conta Parceira com nome'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manage-group screen loads first page and appends more rows by infinite scroll',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: false, hasNestedProfileGroups: true),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        nestedProfileGroups: [_nestedGroupMetadataOnly(memberCount: 9)],
      );
      profilesRepository.nestedGroupMemberPagesByGroupId['partners'] =
          <TenantAdminNestedGroupMemberPage>[
            _nestedGroupMemberPage(
              items: const <Map<String, Object?>>[
                {'id': 'profile-a', 'display_name': 'Alpha profile'},
                {'id': 'profile-b', 'display_name': 'Beta profile'},
                {'id': 'profile-d', 'display_name': 'Delta profile'},
                {'id': 'profile-e', 'display_name': 'Epsilon profile'},
                {'id': 'profile-f', 'display_name': 'Zeta profile'},
                {'id': 'profile-g', 'display_name': 'Eta profile'},
                {'id': 'profile-h', 'display_name': 'Theta profile'},
                {'id': 'profile-i', 'display_name': 'Iota profile'},
              ],
              nextCursor: 'cursor-2',
            ),
            _nestedGroupMemberPage(
              items: const <Map<String, Object?>>[
                {'id': 'profile-c', 'display_name': 'Gamma profile'},
              ],
            ),
          ];
      profilesRepository.accountProfileFetchOverrides['profile-a'] = _profile(
        id: 'profile-a',
        displayName: 'Alpha profile',
        profileType: 'poi',
      );
      profilesRepository.accountProfileFetchOverrides['profile-b'] = _profile(
        id: 'profile-b',
        displayName: 'Beta profile',
        profileType: 'poi',
      );
      profilesRepository.accountProfileFetchOverrides['profile-c'] = _profile(
        id: 'profile-c',
        displayName: 'Gamma profile',
        profileType: 'poi',
      );
      profilesRepository.accountProfileFetchOverrides['profile-d'] = _profile(
        id: 'profile-d',
        displayName: 'Delta profile',
        profileType: 'poi',
      );
      profilesRepository.accountProfileFetchOverrides['profile-e'] = _profile(
        id: 'profile-e',
        displayName: 'Epsilon profile',
        profileType: 'poi',
      );
      profilesRepository.accountProfileFetchOverrides['profile-f'] = _profile(
        id: 'profile-f',
        displayName: 'Zeta profile',
        profileType: 'poi',
      );
      profilesRepository.accountProfileFetchOverrides['profile-g'] = _profile(
        id: 'profile-g',
        displayName: 'Eta profile',
        profileType: 'poi',
      );
      profilesRepository.accountProfileFetchOverrides['profile-h'] = _profile(
        id: 'profile-h',
        displayName: 'Theta profile',
        profileType: 'poi',
      );
      profilesRepository.accountProfileFetchOverrides['profile-i'] = _profile(
        id: 'profile-i',
        displayName: 'Iota profile',
        profileType: 'poi',
      );

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Abas de contas vinculadas'),
        200,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('tenantAdminEditManageGroup_partners')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha profile'), findsOneWidget);
      expect(find.text('Beta profile'), findsOneWidget);
      expect(find.text('Gamma profile'), findsNothing);
      await tester.drag(find.byType(ListView).last, const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.text('Gamma profile'), findsOneWidget);
      expect(find.text('9 perfis carregados'), findsOneWidget);
    },
  );

  testWidgets('creates nested group head from the edit screen dialog', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository.profileTypesToReturn = [
      _profileType(hasGallery: false, hasNestedProfileGroups: true),
    ];
    profilesRepository.profileToReturn = _profile(
      id: 'route-profile',
      nestedProfileGroups: const <TenantAdminNestedProfileGroup>[],
    );

    await _pumpScreen(
      tester,
      TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('tenantAdminEditAddNestedGroupButton')),
      200,
      scrollable: scrollable,
    );
    await tester.tap(
      find.byKey(const Key('tenantAdminEditAddNestedGroupButton')),
    );
    await tester.pumpAndSettle();

    final groupNameField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Nome do grupo',
    );
    expect(groupNameField, findsOneWidget);
    await tester.enterText(groupNameField, 'Parceiros');
    await tester.tap(find.text('Criar grupo'));
    await tester.pumpAndSettle();

    expect(profilesRepository.createNestedProfileGroupCalls, 1);
    expect(
      profilesRepository.lastCreateNestedProfileGroupProfileId,
      'route-profile',
    );
    expect(profilesRepository.lastCreateNestedProfileGroupLabel, 'Parceiros');
    expect(find.text('Parceiros'), findsOneWidget);
    expect(find.text('0 perfis vinculados'), findsOneWidget);
  });

  testWidgets(
    'nested group head create failure stays in the dialog and shows an inline error',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: false, hasNestedProfileGroups: true),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        nestedProfileGroups: const <TenantAdminNestedProfileGroup>[],
      );
      profilesRepository.createNestedProfileGroupError = FormValidationFailure(
        statusCode: 422,
        message: 'The given data was invalid.',
        fieldErrors: <String, List<String>>{
          'nested_profile_groups': const <String>[
            'Nested profile groups exceed the configured limit.',
          ],
        },
      );

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminEditAddNestedGroupButton')),
        200,
        scrollable: scrollable,
      );
      await tester.tap(
        find.byKey(const Key('tenantAdminEditAddNestedGroupButton')),
      );
      await tester.pumpAndSettle();

      final groupNameField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Nome do grupo',
      );
      expect(groupNameField, findsOneWidget);
      await tester.enterText(groupNameField, 'Parceiros');
      await tester.tap(find.text('Criar grupo'));
      await tester.pumpAndSettle();

      expect(profilesRepository.createNestedProfileGroupCalls, 1);
      expect(
        find.textContaining(
          'Nested profile groups exceed the configured limit.',
        ),
        findsOneWidget,
      );
      expect(find.text('0 perfis vinculados'), findsNothing);
    },
  );

  testWidgets(
    'delete nested group head requires confirmation only when the group has members',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: false, hasNestedProfileGroups: true),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[
          _nestedGroupMetadataOnly(memberCount: 2),
        ],
      );

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('tenantAdminEditManageGroup_partners')),
        200,
        scrollable: scrollable,
      );

      await tester.tap(find.byTooltip('Remover grupo'));
      await tester.pumpAndSettle();

      expect(find.text('Excluir grupo'), findsOneWidget);
      expect(
        find.textContaining('A exclusão removerá o grupo e todos os vínculos'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(profilesRepository.deleteNestedProfileGroupCalls, 0);
      expect(find.text('Parceiros'), findsOneWidget);

      await tester.tap(find.byTooltip('Remover grupo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(profilesRepository.deleteNestedProfileGroupCalls, 1);
      expect(
        profilesRepository.lastDeleteNestedProfileGroupProfileId,
        'route-profile',
      );
      expect(
        profilesRepository.lastDeleteNestedProfileGroupGroupId,
        'partners',
      );
      expect(find.text('Parceiros'), findsNothing);
    },
  );

  testWidgets('delete nested empty group head skips destructive confirmation', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository.profileTypesToReturn = [
      _profileType(hasGallery: false, hasNestedProfileGroups: true),
    ];
    profilesRepository.profileToReturn = _profile(
      id: 'route-profile',
      nestedProfileGroups: <TenantAdminNestedProfileGroup>[
        _nestedGroupMetadataOnly(memberCount: 0),
      ],
    );

    await _pumpScreen(
      tester,
      TenantAdminAccountProfileEditScreen(
        accountSlug: 'route-account',
        accountProfileId: 'route-profile',
      ),
    );

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('tenantAdminEditManageGroup_partners')),
      200,
      scrollable: scrollable,
    );

    await tester.tap(find.byTooltip('Remover grupo'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir grupo'), findsNothing);
    expect(profilesRepository.deleteNestedProfileGroupCalls, 1);
    expect(find.text('Parceiros'), findsNothing);
  });

  testWidgets(
    'reopens the nested-group dialog after members-route return and stale backend-only changes',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasGallery: false, hasNestedProfileGroups: true),
      ];
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        nestedProfileGroups: <TenantAdminNestedProfileGroup>[
          _nestedGroupMetadataOnly(memberCount: 1),
        ],
      );
      profilesRepository.nestedGroupMemberPagesByGroupId['partners'] =
          <TenantAdminNestedGroupMemberPage>[
            _nestedGroupMemberPage(items: const <Map<String, Object?>>[]),
          ];

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      final manageGroupButton = find.byKey(
        const Key('tenantAdminEditManageGroup_partners'),
      );
      final addGroupButton = find.byKey(
        const Key('tenantAdminEditAddNestedGroupButton'),
      );
      await tester.scrollUntilVisible(
        manageGroupButton,
        200,
        scrollable: scrollable,
      );
      await tester.tap(manageGroupButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Remover grupo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        nestedProfileGroups: List<TenantAdminNestedProfileGroup>.generate(
          12,
          (index) => _nestedGroupMetadata(
            id: 'stale-group-$index',
            label: 'Grupo stale ${index + 1}',
          ),
          growable: false,
        ),
      );

      await tester.scrollUntilVisible(
        addGroupButton,
        200,
        scrollable: scrollable,
      );
      await tester.tap(addGroupButton);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              widget.decoration?.labelText == 'Nome do grupo',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'sends explicit remove avatar flag when clearing persisted media',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileToReturn = _profile(
        id: 'route-profile',
        avatarUrl: 'https://tenant-a.test/media/account-profiles/avatar.png',
        coverUrl: 'https://tenant-a.test/media/account-profiles/cover.png',
      );

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileEditScreen(
          accountSlug: 'route-account',
          accountProfileId: 'route-profile',
        ),
      );

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('accountProfileEditAvatarRemoveButton')),
        200,
        scrollable: scrollable,
      );
      await tester.tap(
        find.byKey(const ValueKey('accountProfileEditAvatarRemoveButton')),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Salvar alteracoes'),
        200,
        scrollable: scrollable,
      );
      await tester.tap(find.text('Salvar alteracoes'));
      await tester.pumpAndSettle();

      expect(profilesRepository.lastRemoveAvatar, isTrue);
      expect(profilesRepository.lastRemoveCover, isNot(true));
      expect(profilesRepository.profileToReturn.avatarUrl, isNull);
      expect(profilesRepository.profileToReturn.coverUrl, isNotNull);
    },
  );
}

Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: TenantAdminAccountProfileEditRoute.name,
        path: '/',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, _) => child,
      ),
      NamedRouteDef(
        name: TenantAdminAccountProfileGroupMembersRoute.name,
        path: '/profile-group-members',
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
        builder: (_, routeData) {
          final args = routeData
              .argsAs<TenantAdminAccountProfileGroupMembersRouteArgs>();
          return TenantAdminAccountProfileGroupMembersScreen(
            key: args.key,
            accountProfileId: args.accountProfileId,
            group: TenantAdminNestedProfileGroup(
              idValue: TenantAdminNestedProfileGroupTextValue(args.groupId),
              labelValue: TenantAdminNestedProfileGroupTextValue('Grupo'),
              orderValue: TenantAdminNestedProfileGroupOrderValue(),
            ),
          );
        },
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAccountsRepository extends TenantAdminAccountsRepositoryContract {
  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    return [];
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    final account = tenantAdminAccountFromRaw(
      id: 'acc-${accountSlug.value}',
      name: accountSlug.value,
      slug: accountSlug.value,
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
    accountsStreamValue.addValue([account]);
    return account;
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountOnboardingResult> createAccountOnboarding({
    required TenantAdminAccountsRepositoryContractPrimString name,
    required TenantAdminOwnershipState ownershipState,
    required TenantAdminAccountsRepositoryContractPrimString profileType,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountsRepositoryContractPrimString? bio,
    TenantAdminAccountsRepositoryContractPrimString? content,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft> contactChannelDrafts =
        const <BellugaContactChannelDraft>[],
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required TenantAdminAccountsRepositoryContractPrimString accountSlug,
    TenantAdminAccountsRepositoryContractPrimString? name,
    TenantAdminAccountsRepositoryContractPrimString? slug,
    TenantAdminDocument? document,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountPublication? publication,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> restoreAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) {
    throw UnimplementedError();
  }
}

class _FakeAccountProfilesRepository
    extends TenantAdminAccountProfilesRepositoryContract {
  int fetchAccountProfileCalls = 0;
  int updateAccountProfileCalls = 0;
  String? lastUpdatedDisplayName;
  String? lastFetchedProfileId;
  int createNestedProfileGroupCalls = 0;
  String? lastCreateNestedProfileGroupProfileId;
  String? lastCreateNestedProfileGroupLabel;
  Object? createNestedProfileGroupError;
  int deleteNestedProfileGroupCalls = 0;
  String? lastDeleteNestedProfileGroupProfileId;
  String? lastDeleteNestedProfileGroupGroupId;
  Object? deleteNestedProfileGroupError;
  TenantAdminAccountProfileGallerySnapshot? gallerySnapshotToReturn;
  Object? updateGalleryItemError;
  int updateGalleryItemCalls = 0;
  TenantAdminAccountProfile profileToReturn = _profile(id: 'default-profile');
  bool? lastRemoveAvatar;
  bool? lastRemoveCover;
  List<TenantAdminProfileTypeDefinition> profileTypesToReturn = [
    _profileType(hasGallery: true, hasNestedProfileGroups: false),
  ];
  List<TenantAdminAccountProfile> profilesToReturn = [];
  List<List<TenantAdminAccountProfile>> pagedProfilesToReturnByRequest =
      const [];
  final Map<String, TenantAdminAccountProfile> accountProfileFetchOverrides =
      <String, TenantAdminAccountProfile>{};
  List<TenantAdminNestedProfileGroup>? lastNestedProfileGroups;
  final Map<String, List<TenantAdminNestedGroupMemberPage>>
  nestedGroupMemberPagesByGroupId =
      <String, List<TenantAdminNestedGroupMemberPage>>{};
  int fetchAccountProfilesPageCalls = 0;
  int fetchAllNestedGroupMembersCalls = 0;
  String? lastPatchNestedGroupProfileId;
  String? lastPatchNestedGroupId;

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    return _filterProfiles(
      excludeAccountProfileId: excludeAccountProfileId?.value,
    );
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? search,
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoString? profileType,
    TenantAdminAccountProfilesRepoString? contactMode,
    TenantAdminAccountProfilesRepoBool? contactChannelsEnabledOnly,
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    fetchAccountProfilesPageCalls += 1;
    final sourceProfiles =
        pagedProfilesToReturnByRequest.isNotEmpty &&
            fetchAccountProfilesPageCalls <=
                pagedProfilesToReturnByRequest.length
        ? pagedProfilesToReturnByRequest[fetchAccountProfilesPageCalls - 1]
        : profilesToReturn;
    final filtered = _filterProfiles(
      sourceProfiles: sourceProfiles,
      search: search?.value,
      excludeAccountProfileId: excludeAccountProfileId?.value,
    );
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= filtered.length) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
        currentPage: page.value,
        pageSize: pageSize.value,
      );
    }
    final end = start + pageSize.value < filtered.length
        ? start + pageSize.value
        : filtered.length;
    return tenantAdminPagedResultFromRaw(
      items: filtered.sublist(start, end),
      hasMore: end < filtered.length,
      currentPage: page.value,
      pageSize: pageSize.value,
    );
  }

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    fetchAccountProfileCalls += 1;
    lastFetchedProfileId = accountProfileId.value;
    final override = accountProfileFetchOverrides[accountProfileId.value];
    if (override != null) {
      return override;
    }
    return _profile(
      id: accountProfileId.value,
      avatarUrl: profileToReturn.avatarUrl,
      coverUrl: profileToReturn.coverUrl,
      displayName: profileToReturn.displayName,
      profileType: profileToReturn.profileType,
      galleryGroups: profileToReturn.galleryGroups,
      nestedProfileGroups: profileToReturn.nestedProfileGroups,
      contactMode: profileToReturn.contactMode,
      contactSourceAccountProfileId:
          profileToReturn.contactSourceAccountProfileId,
      contactChannels: profileToReturn.contactChannels,
      contactBubbleChannelId: profileToReturn.contactBubbleChannelId,
      effectiveContactChannels: profileToReturn.effectiveContactChannels,
    );
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return profileTypesToReturn;
  }

  @override
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  ) async {
    return (await fetchProfileTypes()).firstWhere(
      (definition) => definition.type == profileType.value,
    );
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required TenantAdminAccountProfilesRepoString accountId,
    required TenantAdminAccountProfilesRepoString profileType,
    required TenantAdminAccountProfilesRepoString displayName,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms taxonomyTerms =
        const TenantAdminTaxonomyTerms.empty(),
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    List<TenantAdminNestedProfileGroup> nestedProfileGroups =
        const <TenantAdminNestedProfileGroup>[],
    BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft> contactChannelDrafts =
        const <BellugaContactChannelDraft>[],
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccountProfile> updateAccountProfile({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    TenantAdminAccountProfilesRepoString? profileType,
    TenantAdminAccountProfilesRepoString? displayName,
    TenantAdminAccountProfilesRepoString? slug,
    TenantAdminAccountProfilesRepoInt? aggregateRevision,
    TenantAdminLocation? location,
    TenantAdminTaxonomyTerms? taxonomyTerms,
    TenantAdminAccountProfilesRepoString? bio,
    TenantAdminAccountProfilesRepoString? content,
    TenantAdminAccountProfilesRepoString? avatarUrl,
    TenantAdminAccountProfilesRepoString? coverUrl,
    TenantAdminAccountProfilesRepoBool? removeAvatar,
    TenantAdminAccountProfilesRepoBool? removeCover,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
    List<TenantAdminNestedProfileGroup>? nestedProfileGroups,
    BellugaContactSourceMode? contactMode,
    TenantAdminAccountProfilesRepoString? contactSourceAccountProfileId,
    List<BellugaContactChannelDraft>? contactChannelDrafts,
    BellugaContactBubbleSelectionMutation bubbleSelection =
        const BellugaContactBubbleSelectionMutation.omit(),
  }) async {
    updateAccountProfileCalls += 1;
    lastUpdatedDisplayName = displayName?.value;
    lastRemoveAvatar = removeAvatar?.value;
    lastRemoveCover = removeCover?.value;
    lastNestedProfileGroups = nestedProfileGroups;
    final nextContactChannels = contactChannelDrafts == null
        ? profileToReturn.contactChannels
        : contactChannelDrafts
              .map(
                (draft) => BellugaContactChannel(
                  id: draft.id ?? 'generated-${draft.draftKey}',
                  type: draft.type,
                  value: draft.value,
                  title: draft.title,
                  initialMessages: draft.initialMessages,
                ),
              )
              .toList(growable: false);
    String? nextBubbleChannelId = profileToReturn.contactBubbleChannelId;
    if (bubbleSelection case BellugaContactBubbleSelectionClear()) {
      nextBubbleChannelId = null;
    } else if (bubbleSelection case BellugaContactBubbleSelectionPersisted(
      :final channelId,
    )) {
      nextBubbleChannelId = channelId;
    } else if (bubbleSelection case BellugaContactBubbleSelectionDraft(
      :final draftKey,
    )) {
      final selectedDraft = contactChannelDrafts
          ?.where((draft) => draft.draftKey == draftKey)
          .toList(growable: false);
      if (selectedDraft != null && selectedDraft.isNotEmpty) {
        final draft = selectedDraft.first;
        nextBubbleChannelId = draft.id ?? 'generated-${draft.draftKey}';
      }
    }
    profileToReturn = tenantAdminAccountProfileFromRaw(
      id: accountProfileId.value,
      accountId: profileToReturn.accountId,
      profileType: profileType?.value ?? profileToReturn.profileType,
      displayName: displayName?.value ?? profileToReturn.displayName,
      slug: slug?.value ?? profileToReturn.slug,
      avatarUrl: removeAvatar?.value == true
          ? null
          : (avatarUrl?.value ?? profileToReturn.avatarUrl),
      coverUrl: removeCover?.value == true
          ? null
          : (coverUrl?.value ?? profileToReturn.coverUrl),
      bio: bio?.value ?? profileToReturn.bio,
      content: content?.value ?? profileToReturn.content,
      location: location ?? profileToReturn.location,
      taxonomyTerms: taxonomyTerms ?? profileToReturn.taxonomyTerms,
      galleryGroups: profileToReturn.galleryGroups,
      nestedProfileGroups:
          nestedProfileGroups ?? profileToReturn.nestedProfileGroups,
      ownershipState: profileToReturn.ownershipState,
      contactMode: contactMode ?? profileToReturn.contactMode,
      contactSourceAccountProfileId:
          contactSourceAccountProfileId?.value ??
          profileToReturn.contactSourceAccountProfileId,
      contactChannels: nextContactChannels,
      contactBubbleChannelId: nextBubbleChannelId,
      effectiveContactChannels: profileToReturn.effectiveContactChannels,
      contactSourceProfile: profileToReturn.contactSourceProfile,
      effectiveContactSourceProfile:
          profileToReturn.effectiveContactSourceProfile,
    );
    return profileToReturn;
  }

  @override
  Future<TenantAdminAccountProfileGallerySnapshot> updateGalleryItem({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoString itemId,
    TenantAdminAccountProfileGalleryItemType? type,
    TenantAdminOptionalTextValue? title,
    TenantAdminOptionalTextValue? description,
    TenantAdminMediaUpload? image,
    TenantAdminAccountProfilesRepoString? youtubeUrl,
  }) async {
    updateGalleryItemCalls += 1;
    if (updateGalleryItemError != null) throw updateGalleryItemError!;
    return gallerySnapshotToReturn!;
  }

  @override
  Future<void> deleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminNestedGroupMemberPage> fetchNestedGroupMembersPage({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    TenantAdminAccountProfilesRepoInt? perPage,
    TenantAdminAccountProfilesRepoString? cursor,
  }) async {
    final pages =
        nestedGroupMemberPagesByGroupId[groupId.value] ??
        <TenantAdminNestedGroupMemberPage>[
          TenantAdminNestedGroupMemberPage(
            items: const <TenantAdminAccountProfileSelectionSummary>[],
            nextCursorValue: TenantAdminOptionalTextValue(),
          ),
        ];
    if (cursor == null || cursor.value.isEmpty) {
      return pages.first;
    }
    final index = pages.indexWhere((page) => page.nextCursor == cursor.value);
    if (index < 0 || index + 1 >= pages.length) {
      return pages.last;
    }
    return pages[index + 1];
  }

  @override
  Future<TenantAdminNestedGroupMemberPage> fetchAllNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
  }) async {
    fetchAllNestedGroupMembersCalls += 1;
    final pages =
        nestedGroupMemberPagesByGroupId[groupId.value] ??
        <TenantAdminNestedGroupMemberPage>[
          TenantAdminNestedGroupMemberPage(
            items: const <TenantAdminAccountProfileSelectionSummary>[],
            nextCursorValue: TenantAdminOptionalTextValue(),
          ),
        ];
    final allItems = pages.expand((page) => page.items).toList(growable: false);
    return TenantAdminNestedGroupMemberPage(
      items: allItems,
      nextCursorValue: TenantAdminOptionalTextValue(),
    );
  }

  @override
  Future<TenantAdminNestedGroupMemberMutationResult> patchNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    List<TenantAdminAccountProfilesRepoString> addIds = const [],
    List<TenantAdminAccountProfilesRepoString> removeIds = const [],
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminNestedGroupLabelMutationResult>
  patchNestedProfileGroupLabel({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoString label,
  }) async {
    lastPatchNestedGroupProfileId = accountProfileId.value;
    lastPatchNestedGroupId = groupId.value;
    return TenantAdminNestedGroupLabelMutationResult(
      idValue: TenantAdminNestedProfileGroupTextValue(groupId.value),
      labelValue: TenantAdminNestedProfileGroupTextValue(
        'Parceiros autoritativos',
      ),
    );
  }

  @override
  Future<TenantAdminNestedGroupHeadMutationResult> createNestedProfileGroup({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString label,
  }) async {
    createNestedProfileGroupCalls += 1;
    lastCreateNestedProfileGroupProfileId = accountProfileId.value;
    lastCreateNestedProfileGroupLabel = label.value;
    final error = createNestedProfileGroupError;
    if (error != null) {
      throw error;
    }

    final nextGroups = <TenantAdminNestedProfileGroup>[
      ...profileToReturn.nestedProfileGroups,
      TenantAdminNestedProfileGroup(
        idValue: TenantAdminNestedProfileGroupTextValue(
          _slugifyGroupId(label.value),
        ),
        labelValue: TenantAdminNestedProfileGroupTextValue(label.value),
        orderValue: TenantAdminNestedProfileGroupOrderValue(
          profileToReturn.nestedProfileGroups.length,
        ),
        memberCountValue: TenantAdminCountValue(0),
      ),
    ];
    profileToReturn = _copyProfileWithNestedGroups(nextGroups);

    return TenantAdminNestedGroupHeadMutationResult(groups: nextGroups);
  }

  @override
  Future<TenantAdminNestedGroupHeadMutationResult> deleteNestedProfileGroup({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
  }) async {
    deleteNestedProfileGroupCalls += 1;
    lastDeleteNestedProfileGroupProfileId = accountProfileId.value;
    lastDeleteNestedProfileGroupGroupId = groupId.value;
    final error = deleteNestedProfileGroupError;
    if (error != null) {
      throw error;
    }

    final nextGroups = profileToReturn.nestedProfileGroups
        .where((group) => group.id != groupId.value)
        .toList(growable: false);
    profileToReturn = _copyProfileWithNestedGroups(nextGroups);

    return TenantAdminNestedGroupHeadMutationResult(
      deletedGroupIdValue: TenantAdminOptionalTextValue()..parse(groupId.value),
      groups: nextGroups,
    );
  }

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    TenantAdminAccountProfilesRepoString? pluralLabel,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProfileType(TenantAdminAccountProfilesRepoString type) {
    throw UnimplementedError();
  }

  List<TenantAdminAccountProfile> _filterProfiles({
    List<TenantAdminAccountProfile>? sourceProfiles,
    String? search,
    String? excludeAccountProfileId,
  }) {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    return (sourceProfiles ?? profilesToReturn)
        .where((profile) {
          if (excludeAccountProfileId != null &&
              excludeAccountProfileId.isNotEmpty &&
              profile.id == excludeAccountProfileId) {
            return false;
          }
          if (normalizedSearch.isEmpty) {
            return true;
          }
          final normalizedSlug = profile.slug?.toLowerCase() ?? '';
          return profile.displayName.toLowerCase().contains(normalizedSearch) ||
              profile.profileType.toLowerCase().contains(normalizedSearch) ||
              normalizedSlug.contains(normalizedSearch);
        })
        .toList(growable: false);
  }

  TenantAdminAccountProfile _copyProfileWithNestedGroups(
    List<TenantAdminNestedProfileGroup> groups,
  ) {
    return tenantAdminAccountProfileFromRaw(
      id: profileToReturn.id,
      accountId: profileToReturn.accountId,
      profileType: profileToReturn.profileType,
      displayName: profileToReturn.displayName,
      slug: profileToReturn.slug,
      avatarUrl: profileToReturn.avatarUrl,
      coverUrl: profileToReturn.coverUrl,
      bio: profileToReturn.bio,
      content: profileToReturn.content,
      location: profileToReturn.location,
      taxonomyTerms: profileToReturn.taxonomyTerms,
      galleryGroups: profileToReturn.galleryGroups,
      nestedProfileGroups: groups,
      ownershipState: profileToReturn.ownershipState,
      contactMode: profileToReturn.contactMode,
      contactSourceAccountProfileId:
          profileToReturn.contactSourceAccountProfileId,
      contactChannels: profileToReturn.contactChannels,
      contactBubbleChannelId: profileToReturn.contactBubbleChannelId,
      effectiveContactChannels: profileToReturn.effectiveContactChannels,
      contactSourceProfile: profileToReturn.contactSourceProfile,
      effectiveContactSourceProfile:
          profileToReturn.effectiveContactSourceProfile,
    );
  }

  String _slugifyGroupId(String label) {
    final normalized = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty
        ? 'group-$createNestedProfileGroupCalls'
        : normalized;
  }
}

class _FakeTaxonomiesRepository
    extends TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return [];
  }

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return [];
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeExternalImageProxy implements TenantAdminExternalImageProxyContract {
  @override
  Future<Uint8List> fetchExternalImageBytes({required Object imageUrl}) async {
    return Uint8List(0);
  }
}

TenantAdminAccountProfile _profile({
  required String id,
  String? displayName,
  String profileType = 'poi',
  String? avatarUrl,
  String? coverUrl,
  List<TenantAdminAccountProfileGalleryGroup> galleryGroups =
      const <TenantAdminAccountProfileGalleryGroup>[],
  TenantAdminAccountProfileGalleryCapabilities? galleryCapabilities,
  List<TenantAdminNestedProfileGroup> nestedProfileGroups =
      const <TenantAdminNestedProfileGroup>[],
  BellugaContactSourceMode contactMode = BellugaContactSourceMode.own,
  String? contactSourceAccountProfileId,
  List<BellugaContactChannel> contactChannels = const <BellugaContactChannel>[],
  String? contactBubbleChannelId,
  List<BellugaContactChannel> effectiveContactChannels =
      const <BellugaContactChannel>[],
}) {
  return tenantAdminAccountProfileFromRaw(
    id: id,
    accountId: 'acc-1',
    profileType: profileType,
    displayName: displayName ?? id,
    slug: 'slug-$id',
    avatarUrl: avatarUrl,
    coverUrl: coverUrl,
    galleryGroups: galleryGroups,
    galleryCapabilities: galleryCapabilities,
    nestedProfileGroups: nestedProfileGroups,
    ownershipState: TenantAdminOwnershipState.tenantOwned,
    contactMode: contactMode,
    contactSourceAccountProfileId: contactSourceAccountProfileId,
    contactChannels: contactChannels,
    contactBubbleChannelId: contactBubbleChannelId,
    effectiveContactChannels: effectiveContactChannels,
  );
}

TenantAdminAccountProfileGalleryGroup _galleryGroup({String? title}) {
  return TenantAdminAccountProfileGalleryGroup(
    groupIdValue: TenantAdminNestedProfileGroupTextValue('group-1'),
    subtitleValue: TenantAdminNestedProfileGroupTextValue('Ambiente'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    items: [_galleryItem(title: title)],
  );
}

TenantAdminAccountProfileGalleryItem _galleryItem({String? title}) {
  return TenantAdminAccountProfileGalleryItem(
    itemIdValue: TenantAdminNestedProfileGroupTextValue('item-1'),
    titleValue: TenantAdminOptionalTextValue()..parse(title),
    descriptionValue: TenantAdminOptionalTextValue()
      ..parse('Vista para o palco'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    imageUrlValue: TenantAdminOptionalUrlValue()
      ..parse('https://tenant.test/gallery/image.jpg'),
    thumbUrlValue: TenantAdminOptionalUrlValue()
      ..parse('https://tenant.test/gallery/thumb.jpg'),
    cardUrlValue: TenantAdminOptionalUrlValue()
      ..parse('https://tenant.test/gallery/card.jpg'),
    modalUrlValue: TenantAdminOptionalUrlValue()
      ..parse('https://tenant.test/gallery/modal.jpg'),
  );
}

TenantAdminProfileTypeDefinition _profileType({
  required bool hasGallery,
  required bool hasNestedProfileGroups,
  bool hasContactChannels = false,
  String type = 'poi',
  String label = 'POI',
}) {
  return tenantAdminProfileTypeDefinitionFromRaw(
    type: type,
    label: label,
    allowedTaxonomies: [],
    capabilities: TenantAdminProfileTypeCapabilities(
      isFavoritable: TenantAdminFlagValue(false),
      isPoiEnabled: TenantAdminFlagValue(false),
      hasBio: TenantAdminFlagValue(false),
      hasContent: TenantAdminFlagValue(false),
      hasTaxonomies: TenantAdminFlagValue(false),
      hasAvatar: TenantAdminFlagValue(true),
      hasCover: TenantAdminFlagValue(true),
      hasEvents: TenantAdminFlagValue(false),
      hasGallery: TenantAdminFlagValue(hasGallery),
      hasNestedProfileGroups: TenantAdminFlagValue(hasNestedProfileGroups),
      hasContactChannels: TenantAdminFlagValue(hasContactChannels),
    ),
  );
}

TenantAdminNestedProfileGroup _nestedGroup() {
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue('partners'),
    labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    accountProfileIdValues: [
      TenantAdminNestedProfileGroupTextValue('profile-partner'),
    ],
  );
}

TenantAdminNestedProfileGroup _nestedGroupMetadataOnly({int memberCount = 1}) {
  return _nestedGroupMetadata(
    id: 'partners',
    label: 'Parceiros',
    memberCount: memberCount,
  );
}

TenantAdminNestedProfileGroup _nestedGroupMetadata({
  required String id,
  required String label,
  int memberCount = 0,
}) {
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue(id),
    labelValue: TenantAdminNestedProfileGroupTextValue(label),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    memberCountValue: TenantAdminCountValue(memberCount),
  );
}

TenantAdminNestedGroupMemberPage _nestedGroupMemberPage({
  required List<Map<String, Object?>> items,
  String? nextCursor,
}) {
  return TenantAdminNestedGroupMemberPage(
    items: items
        .map(
          (item) => TenantAdminAccountProfileSelectionSummary(
            idValue: TenantAdminAccountProfileIdValue(item['id']! as String),
            displayNameValue: TenantAdminOptionalTextValue()
              ..parse(item['display_name'] as String?),
            isQueryableCandidateValue: TenantAdminFlagValue(true),
          ),
        )
        .toList(growable: false),
    nextCursorValue: TenantAdminOptionalTextValue()..parse(nextCursor),
  );
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _TestHttpClient();
  }
}

class _TestHttpClient implements HttpClient {
  bool _autoUncompress = true;

  static final List<int> _transparentImage = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _TestHttpClientRequest(_transparentImage);
  }

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) {
    _autoUncompress = value;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientRequest implements HttpClientRequest {
  _TestHttpClientRequest(this._imageBytes);

  final List<int> _imageBytes;

  @override
  Future<HttpClientResponse> close() async {
    return _TestHttpClientResponse(_imageBytes);
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _TestHttpClientResponse(this._imageBytes);

  final List<int> _imageBytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _imageBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final controller = StreamController<List<int>>();
    controller.add(_imageBytes);
    controller.close();
    return controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
