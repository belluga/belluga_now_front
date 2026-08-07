import 'package:belluga_contact_channels/belluga_contact_channels.dart';
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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_mutation_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_nested_group_member_page.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_aggregate_revision_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_account_profile_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
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
      find.text('Galerias de fotos'),
      200,
      scrollable: scrollable,
    );

    expect(find.text('Galerias de fotos'), findsOneWidget);
    expect(
      find.byKey(const Key('tenantAdminGalleryGroup_group-1')),
      findsOneWidget,
    );
    expect(find.text('Ambiente'), findsOneWidget);
    expect(find.text('Vista para o palco'), findsOneWidget);
  });

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

      expect(profilesRepository.lastGalleryGroups, isNull);
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
  });

  testWidgets(
    'saving edit profile does not hydrate nested group members before submit',
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
          aggregateRevisionValue:
              TenantAdminAccountProfileAggregateRevisionValue(7),
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
          aggregateRevisionValue:
              TenantAdminAccountProfileAggregateRevisionValue(8),
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
      expect(profilesRepository.lastNestedProfileGroups, isNotNull);
      expect(
        profilesRepository.lastNestedProfileGroups!.single.accountProfileIdValues,
        isEmpty,
      );
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
              aggregateRevision: 4,
              nextCursor: 'cursor-2',
            ),
            _nestedGroupMemberPage(
              items: const <Map<String, Object?>>[
                {'id': 'profile-c', 'display_name': 'Gamma profile'},
              ],
              aggregateRevision: 4,
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
  String? lastFetchedProfileId;
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
  List<TenantAdminAccountProfileGalleryUpdateGroup>? lastGalleryGroups;
  List<TenantAdminNestedProfileGroup>? lastNestedProfileGroups;
  final Map<String, List<TenantAdminNestedGroupMemberPage>>
  nestedGroupMemberPagesByGroupId =
      <String, List<TenantAdminNestedGroupMemberPage>>{};
  int fetchAccountProfilesPageCalls = 0;
  int fetchAllNestedGroupMembersCalls = 0;

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
  Future<TenantAdminAccountProfile> updateAccountProfileGallery({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    List<TenantAdminAccountProfileGalleryUpdateGroup> galleryGroups =
        const <TenantAdminAccountProfileGalleryUpdateGroup>[],
  }) async {
    lastGalleryGroups = galleryGroups;
    return profileToReturn;
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
            aggregateRevisionValue:
                TenantAdminAccountProfileAggregateRevisionValue(),
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
            aggregateRevisionValue:
                TenantAdminAccountProfileAggregateRevisionValue(),
            nextCursorValue: TenantAdminOptionalTextValue(),
          ),
        ];
    final allItems = pages.expand((page) => page.items).toList(growable: false);
    final lastPage = pages.last;
    return TenantAdminNestedGroupMemberPage(
      items: allItems,
      aggregateRevisionValue: lastPage.aggregateRevisionValue,
      nextCursorValue: TenantAdminOptionalTextValue(),
    );
  }

  @override
  Future<TenantAdminNestedGroupMemberMutationResult> patchNestedGroupMembers({
    required TenantAdminAccountProfilesRepoString accountProfileId,
    required TenantAdminAccountProfilesRepoString groupId,
    required TenantAdminAccountProfilesRepoInt aggregateRevision,
    List<TenantAdminAccountProfilesRepoString> addIds = const [],
    List<TenantAdminAccountProfilesRepoString> removeIds = const [],
  }) async {
    throw UnimplementedError();
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
    nestedProfileGroups: nestedProfileGroups,
    ownershipState: TenantAdminOwnershipState.tenantOwned,
    contactMode: contactMode,
    contactSourceAccountProfileId: contactSourceAccountProfileId,
    contactChannels: contactChannels,
    contactBubbleChannelId: contactBubbleChannelId,
    effectiveContactChannels: effectiveContactChannels,
  );
}

TenantAdminAccountProfileGalleryGroup _galleryGroup() {
  return TenantAdminAccountProfileGalleryGroup(
    groupIdValue: TenantAdminNestedProfileGroupTextValue('group-1'),
    subtitleValue: TenantAdminNestedProfileGroupTextValue('Ambiente'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    items: [_galleryItem()],
  );
}

TenantAdminAccountProfileGalleryItem _galleryItem() {
  return TenantAdminAccountProfileGalleryItem(
    itemIdValue: TenantAdminNestedProfileGroupTextValue('item-1'),
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
  return TenantAdminNestedProfileGroup(
    idValue: TenantAdminNestedProfileGroupTextValue('partners'),
    labelValue: TenantAdminNestedProfileGroupTextValue('Parceiros'),
    orderValue: TenantAdminNestedProfileGroupOrderValue(0),
    memberCountValue: TenantAdminCountValue(memberCount),
  );
}

TenantAdminNestedGroupMemberPage _nestedGroupMemberPage({
  required List<Map<String, Object?>> items,
  required int aggregateRevision,
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
    aggregateRevisionValue: TenantAdminAccountProfileAggregateRevisionValue(
      aggregateRevision,
    ),
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
