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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile_gallery_group.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
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
      expect(find.textContaining('Atendimento'), findsWidgets);
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

  testWidgets('renders nested group selector when capability is enabled', (
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
      nestedProfileGroups: [_nestedGroup()],
    );
    profilesRepository.profilesToReturn = [
      _profile(
        id: 'profile-partner',
        displayName: 'Conta Parceira',
        profileType: 'poi',
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
      find.text('Abas de contas vinculadas'),
      200,
      scrollable: scrollable,
    );

    expect(find.text('Abas de contas vinculadas'), findsOneWidget);
    expect(find.text('Conta Parceira'), findsOneWidget);
    expect(find.text('1 Account(s) selecionada(s)'), findsOneWidget);
  });

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
  List<TenantAdminAccountProfileGalleryUpdateGroup>? lastGalleryGroups;
  List<TenantAdminNestedProfileGroup>? lastNestedProfileGroups;

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
    TenantAdminAccountProfilesRepoBool? queryableOnly,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    final filtered = _filterProfiles(
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
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchContactSourceCandidatesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? excludeAccountProfileId,
  }) async {
    final candidates = _filterProfiles(
      excludeAccountProfileId: excludeAccountProfileId?.value,
    );
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= candidates.length) {
      return tenantAdminPagedResultFromRaw(
        items: const <TenantAdminAccountProfile>[],
        hasMore: false,
        currentPage: page.value,
        pageSize: pageSize.value,
      );
    }
    final end = start + pageSize.value < candidates.length
        ? start + pageSize.value
        : candidates.length;
    return tenantAdminPagedResultFromRaw(
      items: candidates.sublist(start, end),
      hasMore: end < candidates.length,
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
    String? search,
    String? excludeAccountProfileId,
  }) {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    return profilesToReturn
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
}) {
  return tenantAdminProfileTypeDefinitionFromRaw(
    type: 'poi',
    label: 'POI',
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
