import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/services/tenant_admin_location_selection_contract.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profiles_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('loads account detail using route slug on init', (tester) async {
    final accountsRepository = _FakeAccountsRepository();
    final controller =
        _registerController(accountsRepository: accountsRepository);

    await _pumpScreen(
      tester,
      TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
    );

    expect(accountsRepository.fetchAccountBySlugCalls, 1);
    expect(accountsRepository.lastFetchedSlug, 'yuri-dias');
    expect(controller.accountStreamValue.value, isNotNull);
    expect(controller.accountStreamValue.value!.slug, 'yuri-dias');
    expect(find.text('Conta: yuri-dias'), findsOneWidget);
  });

  testWidgets('reflects repository account stream updates without reload',
      (tester) async {
    final accountsRepository = _FakeAccountsRepository();
    _registerController(accountsRepository: accountsRepository);

    await _pumpScreen(
      tester,
      TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
    );

    expect(find.text('Conta base'), findsOneWidget);

    accountsRepository.emitUpdatedAccount(
      name: 'Conta atualizada',
      slug: 'yuri-dias',
    );
    await tester.pumpAndSettle();

    expect(find.text('Conta atualizada'), findsOneWidget);
    expect(accountsRepository.fetchAccountBySlugCalls, 1);
  });

  testWidgets('reloads account detail after returning from profile edit route',
      (tester) async {
    final accountsRepository = _FakeAccountsRepository();
    _registerController(accountsRepository: accountsRepository);

    await _pumpScreen(
      tester,
      TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
    );

    expect(accountsRepository.fetchAccountBySlugCalls, 1);

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('profile_edit_close')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('profile_edit_close')));
    await tester.pumpAndSettle();

    expect(accountsRepository.fetchAccountBySlugCalls, 2);
  });

  testWidgets('hides delete action for tenant-owned accounts', (tester) async {
    final tenantOwnedRepository = _FakeAccountsRepository(
      initialOwnershipState: TenantAdminOwnershipState.tenantOwned,
    );
    _registerController(accountsRepository: tenantOwnedRepository);

    await _pumpScreen(
      tester,
      TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
    );

    expect(find.text('Excluir conta'), findsNothing);
  });

  testWidgets('shows delete action for unmanaged accounts', (tester) async {
    final unmanagedRepository = _FakeAccountsRepository(
      initialOwnershipState: TenantAdminOwnershipState.unmanaged,
    );
    _registerController(accountsRepository: unmanagedRepository);

    await _pumpScreen(
      tester,
      TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
    );

    expect(find.text('Excluir conta'), findsOneWidget);
  });

  testWidgets('deletes unmanaged account after confirmation', (tester) async {
    final accountsRepository = _FakeAccountsRepository(
      initialOwnershipState: TenantAdminOwnershipState.unmanaged,
    );
    _registerController(accountsRepository: accountsRepository);

    await _pumpScreen(
      tester,
      TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
    );

    await tester.tap(find.text('Excluir conta'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir conta'), findsNWidgets(2));

    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();

    expect(accountsRepository.deleteAccountCalls, 1);
    expect(accountsRepository.lastDeletedSlug, 'yuri-dias');
  });

  testWidgets(
      'missing profile renders invariant-broken state and no create CTA',
      (tester) async {
    final accountsRepository = _FakeAccountsRepository();
    _registerController(
      accountsRepository: accountsRepository,
      withProfile: false,
    );

    await _pumpScreen(
      tester,
      TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
    );

    expect(find.text('Inconsistência de dados'), findsOneWidget);
    expect(find.textContaining('Conta sem perfil detectada.'), findsOneWidget);
    expect(find.text('Criar Perfil'), findsNothing);
  });
}

TenantAdminAccountDetailController _registerController({
  required _FakeAccountsRepository accountsRepository,
  bool withProfile = true,
}) {
  final profilesRepository = _FakeAccountProfilesRepository(
    withProfile: withProfile,
  );
  final taxonomiesRepository = _FakeTaxonomiesRepository();
  final TenantAdminLocationSelectionContract locationSelectionService =
      TenantAdminLocationSelectionService();

  final controller = TenantAdminAccountProfilesController(
    profilesRepository: profilesRepository,
    accountsRepository: accountsRepository,
    taxonomiesRepository: taxonomiesRepository,
    locationSelectionService: locationSelectionService,
  );

  final detailController = TenantAdminAccountDetailController(
    delegate: controller,
  );

  GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(controller);
  GetIt.I.registerSingleton<TenantAdminAccountDetailController>(
    detailController,
  );
  return detailController;
}

Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'detail-test',
        path: '/',
        builder: (_, __) => child,
      ),
      NamedRouteDef(
        name: TenantAdminAccountProfileEditRoute.name,
        path: '/accounts/:accountSlug/profile/:accountProfileId/edit',
        builder: (_, __) => const _TestProfileEditRouteScreen(),
      ),
    ],
  )..ignorePopCompleters = true;

  await tester.pumpWidget(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(),
      routerDelegate: router.delegate(),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestProfileEditRouteScreen extends StatelessWidget {
  const _TestProfileEditRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('profile_edit_close'),
          onPressed: () => context.router.maybePop(),
          child: const Text('Voltar'),
        ),
      ),
    );
  }
}

class _FakeAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  _FakeAccountsRepository({
    this.initialOwnershipState = TenantAdminOwnershipState.tenantOwned,
  }) {
    _seedAccount(
      tenantAdminAccountFromRaw(
        id: 'acc-1',
        name: 'Conta base',
        slug: 'yuri-dias',
        document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
        ownershipState: initialOwnershipState,
      ),
    );
  }

  final TenantAdminOwnershipState initialOwnershipState;
  final Map<String, TenantAdminAccount> _accountsById =
      <String, TenantAdminAccount>{};

  int fetchAccountBySlugCalls = 0;
  String? lastFetchedSlug;
  int deleteAccountCalls = 0;
  String? lastDeletedSlug;

  @override
  Future<void> loadAccounts({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {}

  @override
  Future<void> loadNextAccountsPage({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {}

  @override
  void resetAccountsState() {}

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    fetchAccountBySlugCalls += 1;
    lastFetchedSlug = accountSlug.value;
    final account = _accountsById.values.firstWhere(
      (entry) => entry.slug == accountSlug.value,
      orElse: () => tenantAdminAccountFromRaw(
        id: 'acc-1',
        name: 'Conta base',
        slug: accountSlug.value,
        document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
    );
    _seedAccount(account);
    return account;
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async {
    return List<TenantAdminAccount>.unmodifiable(_accountsById.values);
  }

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    return tenantAdminPagedAccountsResultFromRaw(
      accounts: List<TenantAdminAccount>.unmodifiable(_accountsById.values),
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required TenantAdminAccountsRepositoryContractPrimString name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? organizationId,
  }) async {
    final created = tenantAdminAccountFromRaw(
      id: 'acc-created',
      name: name.value,
      slug: 'acc-created',
      document:
          document ?? tenantAdminDocumentFromRaw(type: 'cpf', number: '001'),
      ownershipState: ownershipState,
      organizationId: organizationId?.value,
    );
    _seedAccount(created);
    return created;
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
  }) async {
    final account = await createAccount(
      name: name,
      ownershipState: ownershipState,
    );
    return TenantAdminAccountOnboardingResult(
      account: account,
      accountProfile: tenantAdminAccountProfileFromRaw(
        id: 'profile-onboarding',
        accountId: account.id,
        profileType: profileType.value,
        displayName: name.value,
        location: location,
        taxonomyTerms: taxonomyTerms,
        bio: bio?.value,
        content: content?.value,
      ),
    );
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required TenantAdminAccountsRepositoryContractPrimString accountSlug,
    TenantAdminAccountsRepositoryContractPrimString? name,
    TenantAdminAccountsRepositoryContractPrimString? slug,
    TenantAdminDocument? document,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    final current = await fetchAccountBySlug(accountSlug);
    final updated = tenantAdminAccountFromRaw(
      id: current.id,
      name: name?.value ?? current.name,
      slug: slug?.value ?? current.slug,
      document: document ?? current.document,
      ownershipState: ownershipState ?? current.ownershipState,
      organizationId: current.organizationId,
    );
    _seedAccount(updated);
    return updated;
  }

  void emitUpdatedAccount({required String name, required String slug}) {
    final current = _accountsById['acc-1'];
    if (current == null) {
      return;
    }
    _seedAccount(
      tenantAdminAccountFromRaw(
        id: current.id,
        name: name,
        slug: slug,
        document: current.document,
        ownershipState: current.ownershipState,
        organizationId: current.organizationId,
      ),
    );
  }

  @override
  Future<void> deleteAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    deleteAccountCalls += 1;
    lastDeletedSlug = accountSlug.value;
    final accountToRemove = _accountsById.values.firstWhere(
      (entry) => entry.slug == accountSlug.value,
      orElse: () => tenantAdminAccountFromRaw(
        id: '',
        name: '',
        slug: '',
        document: tenantAdminDocumentFromRaw(type: 'cpf', number: ''),
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
    );
    if (accountToRemove.id.isNotEmpty) {
      _accountsById.remove(accountToRemove.id);
      accountsStreamValue.addValue(
        List<TenantAdminAccount>.unmodifiable(_accountsById.values),
      );
    }
  }

  @override
  Future<TenantAdminAccount> restoreAccount(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    return fetchAccountBySlug(accountSlug);
  }

  @override
  Future<void> forceDeleteAccount(
      TenantAdminAccountsRepositoryContractPrimString accountSlug) async {}

  void _seedAccount(TenantAdminAccount account) {
    _accountsById[account.id] = account;
    accountsStreamValue.addValue(
      List<TenantAdminAccount>.unmodifiable(_accountsById.values),
    );
  }
}

class _FakeAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({required this.withProfile});

  final bool withProfile;

  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    TenantAdminAccountProfilesRepoString? accountId,
  }) async {
    if (accountId == null || !withProfile) {
      return [];
    }
    return [
      tenantAdminAccountProfileFromRaw(
        id: 'profile-1',
        accountId: accountId,
        profileType: 'artist',
        displayName: 'Perfil',
      ),
    ];
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return [
      tenantAdminProfileTypeDefinitionFromRaw(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(false),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(true),
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
  }) async {
    final types = await fetchProfileTypes();
    return tenantAdminPagedResultFromRaw(
      items: types,
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'artist',
      displayName: 'Perfil',
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
  }) async {
    return tenantAdminAccountProfileFromRaw(
      id: 'profile-created',
      accountId: accountId,
      profileType: profileType,
      displayName: displayName,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
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
  }) async {
    return tenantAdminAccountProfileFromRaw(
      id: accountProfileId,
      accountId: 'acc-1',
      profileType: profileType ?? 'artist',
      displayName: displayName ?? 'Perfil',
      slug: slug ?? 'perfil',
      location: location,
      taxonomyTerms: taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
  }

  @override
  Future<void> deleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    TenantAdminAccountProfilesRepoString accountProfileId,
  ) async {
    return fetchAccountProfile(accountProfileId);
  }

  @override
  Future<void> forceDeleteAccountProfile(
      TenantAdminAccountProfilesRepoString accountProfileId) async {}

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required TenantAdminAccountProfilesRepoString type,
    required TenantAdminAccountProfilesRepoString label,
    List<TenantAdminAccountProfilesRepoString> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required TenantAdminAccountProfilesRepoString type,
    TenantAdminAccountProfilesRepoString? newType,
    TenantAdminAccountProfilesRepoString? label,
    List<TenantAdminAccountProfilesRepoString>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return tenantAdminProfileTypeDefinitionFromRaw(
      type: newType ?? type,
      label: label ?? 'Updated',
      allowedTaxonomies: allowedTaxonomies ?? [],
      capabilities: capabilities ??
          TenantAdminProfileTypeCapabilities(
            isFavoritable: TenantAdminFlagValue(true),
            isPoiEnabled: TenantAdminFlagValue(false),
            hasBio: TenantAdminFlagValue(true),
            hasContent: TenantAdminFlagValue(true),
            hasTaxonomies: TenantAdminFlagValue(true),
            hasAvatar: TenantAdminFlagValue(true),
            hasCover: TenantAdminFlagValue(true),
            hasEvents: TenantAdminFlagValue(true),
          ),
    );
  }

  @override
  Future<void> deleteProfileType(
      TenantAdminAccountProfilesRepoString type) async {}
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return [];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
    required List<TenantAdminTaxRepoString> appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    return tenantAdminTaxonomyDefinitionFromRaw(
      id: 'taxonomy-1',
      slug: slug,
      name: name,
      appliesTo: appliesTo,
      icon: icon,
      color: color,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required TenantAdminTaxRepoString taxonomyId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
    List<TenantAdminTaxRepoString>? appliesTo,
    TenantAdminTaxRepoString? icon,
    TenantAdminTaxRepoString? color,
  }) async {
    return tenantAdminTaxonomyDefinitionFromRaw(
      id: taxonomyId,
      slug: slug ?? 'taxonomy',
      name: name ?? 'Taxonomy',
      appliesTo: appliesTo ?? [],
      icon: icon,
      color: color,
    );
  }

  @override
  Future<void> deleteTaxonomy(TenantAdminTaxRepoString taxonomyId) async {}

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required TenantAdminTaxRepoString taxonomyId,
  }) async {
    return [];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoInt page,
    required TenantAdminTaxRepoInt pageSize,
  }) async {
    return tenantAdminPagedResultFromRaw(
      items: <TenantAdminTaxonomyTermDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString slug,
    required TenantAdminTaxRepoString name,
  }) async {
    return tenantAdminTaxonomyTermDefinitionFromRaw(
      id: 'term-1',
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
    TenantAdminTaxRepoString? slug,
    TenantAdminTaxRepoString? name,
  }) async {
    return tenantAdminTaxonomyTermDefinitionFromRaw(
      id: termId,
      taxonomyId: taxonomyId,
      slug: slug ?? 'term',
      name: name ?? 'Term',
    );
  }

  @override
  Future<void> deleteTerm({
    required TenantAdminTaxRepoString taxonomyId,
    required TenantAdminTaxRepoString termId,
  }) async {}
}
