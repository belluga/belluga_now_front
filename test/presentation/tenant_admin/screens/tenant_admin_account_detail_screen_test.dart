import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/support/canonical_route_family.dart';
import 'package:belluga_now/application/router/support/canonical_route_meta.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
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
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_detail_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

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

  testWidgets('renders account profile rich text readback faithfully',
      (tester) async {
    final accountsRepository = _FakeAccountsRepository();
    _registerController(
      accountsRepository: accountsRepository,
      profileBio: 'Primeira linha\nSegunda linha\n\nNovo parágrafo',
      profileContent: '<p><strong>Conteúdo seguro</strong></p>',
    );

    await _pumpScreen(
      tester,
      TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
    );

    expect(find.text('Primeira linha'), findsOneWidget);
    expect(find.text('Segunda linha'), findsOneWidget);
    expect(find.text('Novo parágrafo'), findsOneWidget);
    expect(find.text('Conteúdo seguro'), findsOneWidget);
    expect(find.textContaining('<p>'), findsNothing);
    expect(find.textContaining('<strong>'), findsNothing);
  });

  test('loadAccountDetail invalidates stale async work after dispose',
      () async {
    final accountsRepository = _DelayedFetchAccountsRepository();
    final profilesRepository =
        _FakeAccountProfilesRepository(withProfile: true);
    final controller = TenantAdminAccountDetailController(
      profilesRepository: profilesRepository,
      accountsRepository: accountsRepository,
    );

    final loadFuture = controller.loadAccountDetail('yuri-dias');
    await Future<void>.delayed(Duration.zero);

    expect(accountsRepository.fetchAccountBySlugCalls, 1);
    expect(accountsRepository.watchLoadedAccountCalls, 0);

    controller.onDispose();
    accountsRepository.completeFetch();

    await loadFuture;

    expect(accountsRepository.watchLoadedAccountCalls, 0);
  });
}

TenantAdminAccountDetailController _registerController({
  required _FakeAccountsRepository accountsRepository,
  bool withProfile = true,
  String? profileBio,
  String? profileContent,
}) {
  final profilesRepository = _FakeAccountProfilesRepository(
    withProfile: withProfile,
    profileBio: profileBio,
    profileContent: profileContent,
  );
  final detailController = TenantAdminAccountDetailController(
    profilesRepository: profilesRepository,
    accountsRepository: accountsRepository,
  );

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
        meta: canonicalRouteMeta(
          family: CanonicalRouteFamily.tenantAdminAccountsInternal,
          chromeMode: RouteChromeMode.fullscreen,
        ),
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

class _DelayedFetchAccountsRepository extends _FakeAccountsRepository {
  final Completer<TenantAdminAccount> _fetchCompleter =
      Completer<TenantAdminAccount>();

  int watchLoadedAccountCalls = 0;

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
    TenantAdminAccountsRepositoryContractPrimString accountSlug,
  ) async {
    fetchAccountBySlugCalls += 1;
    lastFetchedSlug = accountSlug.value;
    return _fetchCompleter.future;
  }

  @override
  TenantAdminLoadedAccountWatch watchLoadedAccount({
    TenantAdminAccountsRepositoryContractPrimString? accountId,
    TenantAdminAccountsRepositoryContractPrimString? accountSlug,
  }) {
    watchLoadedAccountCalls += 1;
    return super.watchLoadedAccount(
      accountId: accountId,
      accountSlug: accountSlug,
    );
  }

  void completeFetch() {
    if (_fetchCompleter.isCompleted) {
      return;
    }
    final account = tenantAdminAccountFromRaw(
      id: 'acc-1',
      name: 'Conta base',
      slug: 'yuri-dias',
      document: tenantAdminDocumentFromRaw(type: 'cpf', number: '000'),
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
    _seedAccount(account);
    _fetchCompleter.complete(account);
  }
}

class _FakeAccountProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({
    required this.withProfile,
    this.profileBio,
    this.profileContent,
  });

  final bool withProfile;
  final String? profileBio;
  final String? profileContent;

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
        accountId: accountId.value,
        profileType: 'artist',
        displayName: 'Perfil',
        bio: profileBio,
        content: profileContent,
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
  Future<TenantAdminProfileTypeDefinition> fetchProfileType(
    TenantAdminAccountProfilesRepoString profileType,
  ) async {
    return (await fetchProfileTypes()).firstWhere(
      (definition) => definition.type == profileType.value,
    );
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
      bio: profileBio,
      content: profileContent,
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
      accountId: accountId.value,
      profileType: profileType.value,
      displayName: displayName.value,
      location: location,
      taxonomyTerms: taxonomyTerms,
      bio: bio?.value,
      content: content?.value,
      avatarUrl: avatarUrl?.value,
      coverUrl: coverUrl?.value,
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
      id: accountProfileId.value,
      accountId: 'acc-1',
      profileType: profileType?.value ?? 'artist',
      displayName: displayName?.value ?? 'Perfil',
      slug: slug?.value ?? 'perfil',
      location: location,
      taxonomyTerms: taxonomyTerms ?? const TenantAdminTaxonomyTerms.empty(),
      bio: bio?.value,
      content: content?.value,
      avatarUrl: avatarUrl?.value,
      coverUrl: coverUrl?.value,
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
    TenantAdminAccountProfilesRepoString? pluralLabel,
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
    TenantAdminAccountProfilesRepoString? pluralLabel,
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
