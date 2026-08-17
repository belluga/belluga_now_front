import 'package:belluga_contact_channels/belluga_contact_channels.dart';
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
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_create_screen.dart';
import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_image_ingestion_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

    // Simulate stale singleton controller state from a previous session.
    controller.accountStreamValue.addValue(_account(slug: 'stale-account'));

    GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(controller);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'prefers route account slug over cached controller slug on init',
    (tester) async {
      final accountsRepository =
          GetIt.I.get<TenantAdminAccountsRepositoryContract>()
              as _FakeAccountsRepository;

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileCreateScreen(accountSlug: 'route-account'),
      );

      expect(accountsRepository.fetchAccountBySlugCalls, 1);
      expect(accountsRepository.lastFetchedSlug, 'route-account');
    },
  );

  testWidgets(
    'hides nested group editor when profile type disables capability',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      profilesRepository.profileTypesToReturn = [
        _profileType(hasNestedProfileGroups: false),
      ];

      await _pumpScreen(
        tester,
        TenantAdminAccountProfileCreateScreen(accountSlug: 'route-account'),
      );

      await _selectProfileType(tester, 'Venue');

      expect(find.text('Abas de contas vinculadas'), findsNothing);
      expect(
        find.byKey(const Key('tenantAdminCreateAddNestedGroupButton')),
        findsNothing,
      );
    },
  );

  testWidgets('shows save-first guidance for nested groups on create', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository.profileTypesToReturn = [
      _profileType(type: 'venue', label: 'Venue', hasNestedProfileGroups: true),
      _profileType(
        type: 'publisher',
        label: 'Publisher',
        hasNestedProfileGroups: false,
      ),
    ];
    await _pumpScreen(
      tester,
      TenantAdminAccountProfileCreateScreen(accountSlug: 'route-account'),
    );

    await _selectProfileType(tester, 'Venue');

    expect(find.text('Abas de contas vinculadas'), findsOneWidget);
    expect(
      find.byKey(const Key('tenantAdminCreateAddNestedGroupButton')),
      findsNothing,
    );
    expect(find.text('Gerenciar perfis'), findsNothing);
    expect(find.text('Selecionar perfis'), findsNothing);
    expect(
      find.text(
        'Salve o perfil primeiro. Depois disso, a edição de grupos acontece de forma independente, com criação e exclusão persistidas imediatamente.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('create-screen nested groups stay inert before the first save', (
    tester,
  ) async {
    final profilesRepository =
        GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
            as _FakeAccountProfilesRepository;
    profilesRepository.profileTypesToReturn = [
      _profileType(type: 'venue', label: 'Venue', hasNestedProfileGroups: true),
    ];
    await _pumpScreen(
      tester,
      TenantAdminAccountProfileCreateScreen(accountSlug: 'route-account'),
    );

    await _selectProfileType(tester, 'Venue');
    final baselineFetchCalls = profilesRepository.fetchAccountProfilesPageCalls;

    await tester.pumpAndSettle();

    expect(
      profilesRepository.fetchAccountProfilesPageCalls,
      baselineFetchCalls,
    );
    expect(
      find.byKey(const Key('tenantAdminCreateAddNestedGroupButton')),
      findsNothing,
    );
    expect(find.text('Gerenciar perfis'), findsNothing);
    expect(find.text('Selecionar perfis'), findsNothing);
  });

  testWidgets(
    'renders the source bubble selection as an inert mirrored indicator',
    (tester) async {
      final profilesRepository =
          GetIt.I.get<TenantAdminAccountProfilesRepositoryContract>()
              as _FakeAccountProfilesRepository;
      final sourceChannel = BellugaContactChannel(
        id: 'create-source-whatsapp',
        type: BellugaContactChannelType.whatsapp,
        value: '+55 (27) 99999-9999',
      );
      final sourceProfile = _profile(
        id: '507f1f77bcf86cd799439101',
        displayName: 'Perfil Fonte',
        contactChannels: [sourceChannel],
        effectiveContactChannels: [sourceChannel],
        contactBubbleChannelId: sourceChannel.id,
      );
      profilesRepository.profileTypesToReturn = [
        _profileType(hasNestedProfileGroups: false, hasContactChannels: true),
      ];
      profilesRepository.profilesToReturn = [sourceProfile];

      await _pumpScreen(
        tester,
        const TenantAdminAccountProfileCreateScreen(
          accountSlug: 'route-account',
        ),
      );
      await _selectProfileType(tester, 'Venue');

      final controller = GetIt.I.get<TenantAdminAccountProfilesController>();
      controller.updateCreateContactMode(
        BellugaContactSourceMode.mirroredAccountProfile,
      );
      controller.updateCreateContactSourceAccountProfileId(sourceProfile.id);
      await tester.pumpAndSettle();

      final toggle = find
          .byKey(
            const Key(
              'tenantAdminCreateMirroredBubbleToggle_create-source-whatsapp',
            ),
          )
          .last;
      await tester.ensureVisible(toggle);

      final switchListTile = tester.widget<SwitchListTile>(toggle);
      expect(switchListTile.value, isTrue);
      expect(switchListTile.onChanged, isNull);

      final bubbleSelectionBefore =
          controller.createStateStreamValue.value.contactBubbleSelection;
      await tester.tap(toggle);
      await tester.pump();
      await tester.tap(
        find.descendant(of: toggle, matching: find.byType(Switch)),
      );
      await tester.pump();

      expect(
        controller.createStateStreamValue.value.contactBubbleSelection,
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
      id: 'create-source-whatsapp-off',
      type: BellugaContactChannelType.whatsapp,
      value: '+55 (27) 98888-7777',
    );
    final sourceProfile = _profile(
      id: '507f1f77bcf86cd799439102',
      displayName: 'Perfil Fonte Sem Balao',
      contactChannels: [sourceChannel],
      effectiveContactChannels: [sourceChannel],
    );
    profilesRepository.profileTypesToReturn = [
      _profileType(hasNestedProfileGroups: false, hasContactChannels: true),
    ];
    profilesRepository.profilesToReturn = [sourceProfile];

    await _pumpScreen(
      tester,
      const TenantAdminAccountProfileCreateScreen(accountSlug: 'route-account'),
    );
    await _selectProfileType(tester, 'Venue');

    final controller = GetIt.I.get<TenantAdminAccountProfilesController>();
    controller.updateCreateContactBubbleChannelId(sourceChannel.id);
    controller.updateCreateContactMode(
      BellugaContactSourceMode.mirroredAccountProfile,
    );
    controller.updateCreateContactSourceAccountProfileId(sourceProfile.id);
    await tester.pumpAndSettle();

    final toggle = find
        .byKey(
          const Key(
            'tenantAdminCreateMirroredBubbleToggle_create-source-whatsapp-off',
          ),
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
    profilesRepository.profileTypesToReturn = [
      _profileType(hasNestedProfileGroups: false, hasContactChannels: true),
    ];

    await _pumpScreen(
      tester,
      const TenantAdminAccountProfileCreateScreen(accountSlug: 'route-account'),
    );
    await _selectProfileType(tester, 'Venue');

    final addChannel = find.byKey(
      const Key('tenantAdminAddContactChannel_whatsapp'),
    );
    await tester.ensureVisible(addChannel);
    await tester.tap(addChannel);
    await tester.pump();

    final controller = GetIt.I.get<TenantAdminAccountProfilesController>();
    final draft =
        controller.createStateStreamValue.value.contactChannelDrafts.single;
    final toggle = find.byKey(
      Key('tenantAdminContactBubbleToggle_${draft.draftKey}'),
    );
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();

    expect(
      controller.createStateStreamValue.value.contactBubbleSelection,
      isA<BellugaContactBubbleSelectionDraft>().having(
        (selection) => selection.draftKey,
        'draftKey',
        draft.draftKey,
      ),
    );
  });
}

Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: TenantAdminAccountProfileCreateRoute.name,
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
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _selectProfileType(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

class _FakeAccountsRepository extends TenantAdminAccountsRepositoryContract {
  int fetchAccountBySlugCalls = 0;
  String? lastFetchedSlug;

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    return [];
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    fetchAccountBySlugCalls += 1;
    lastFetchedSlug = accountSlug.value;

    final account = _account(slug: accountSlug.value);
    // Seed the list stream so watchLoadedAccount has something to resolve.
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
  List<TenantAdminAccountProfile> profilesToReturn = [];
  List<List<TenantAdminAccountProfile>> pagedProfilesToReturnByRequest =
      const [];
  List<TenantAdminProfileTypeDefinition> profileTypesToReturn = [
    _profileType(hasNestedProfileGroups: true),
  ];
  int fetchAccountProfilesPageCalls = 0;

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
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return profileTypesToReturn;
  }

  @override
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  ) async {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
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

TenantAdminAccount _account({required String slug}) {
  return tenantAdminAccountFromRaw(
    id: 'acc-$slug',
    name: slug,
    slug: slug,
    document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
    ownershipState: TenantAdminOwnershipState.tenantOwned,
  );
}

TenantAdminAccountProfile _profile({
  required String id,
  required String displayName,
  String profileType = 'venue',
  List<BellugaContactChannel> contactChannels = const <BellugaContactChannel>[],
  String? contactBubbleChannelId,
  List<BellugaContactChannel> effectiveContactChannels =
      const <BellugaContactChannel>[],
}) {
  return tenantAdminAccountProfileFromRaw(
    id: id,
    accountId: 'acc-route-account',
    profileType: profileType,
    displayName: displayName,
    slug: id,
    contactChannels: contactChannels,
    contactBubbleChannelId: contactBubbleChannelId,
    effectiveContactChannels: effectiveContactChannels,
  );
}

TenantAdminProfileTypeDefinition _profileType({
  required bool hasNestedProfileGroups,
  bool hasContactChannels = false,
  String type = 'venue',
  String label = 'Venue',
}) {
  return tenantAdminProfileTypeDefinitionFromRaw(
    type: type,
    label: label,
    allowedTaxonomies: const [],
    capabilities: TenantAdminProfileTypeCapabilities(
      isFavoritable: TenantAdminFlagValue(false),
      isPoiEnabled: TenantAdminFlagValue(false),
      hasBio: TenantAdminFlagValue(false),
      hasContent: TenantAdminFlagValue(false),
      hasTaxonomies: TenantAdminFlagValue(false),
      hasAvatar: TenantAdminFlagValue(false),
      hasCover: TenantAdminFlagValue(false),
      hasEvents: TenantAdminFlagValue(false),
      hasNestedProfileGroups: TenantAdminFlagValue(hasNestedProfileGroups),
      hasContactChannels: TenantAdminFlagValue(hasContactChannels),
    ),
  );
}
