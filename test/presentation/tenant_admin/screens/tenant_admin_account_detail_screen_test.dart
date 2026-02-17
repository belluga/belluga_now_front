import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_taxonomies_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
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
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

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
      const TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
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
      const TenantAdminAccountDetailScreen(accountSlug: 'yuri-dias'),
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
}

TenantAdminAccountProfilesController _registerController({
  required _FakeAccountsRepository accountsRepository,
}) {
  final profilesRepository = _FakeAccountProfilesRepository();
  final taxonomiesRepository = _FakeTaxonomiesRepository();
  final TenantAdminLocationSelectionContract locationSelectionService =
      TenantAdminLocationSelectionService();

  final controller = TenantAdminAccountProfilesController(
    profilesRepository: profilesRepository,
    accountsRepository: accountsRepository,
    taxonomiesRepository: taxonomiesRepository,
    locationSelectionService: locationSelectionService,
  );

  GetIt.I.registerSingleton<TenantAdminAccountProfilesController>(controller);
  return controller;
}

Future<void> _pumpScreen(WidgetTester tester, Widget child) async {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'detail-test',
        path: '/',
        builder: (_, __) => child,
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

class _FakeAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  _FakeAccountsRepository() {
    _seedAccount(
      const TenantAdminAccount(
        id: 'acc-1',
        name: 'Conta base',
        slug: 'yuri-dias',
        document: TenantAdminDocument(type: 'cpf', number: '000'),
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
    );
  }

  final Map<String, TenantAdminAccount> _accountsById =
      <String, TenantAdminAccount>{};

  int fetchAccountBySlugCalls = 0;
  String? lastFetchedSlug;

  @override
  final StreamValue<List<TenantAdminAccount>?> accountsStreamValue =
      StreamValue<List<TenantAdminAccount>?>(defaultValue: const []);

  @override
  final StreamValue<bool> hasMoreAccountsStreamValue =
      StreamValue<bool>(defaultValue: false);

  @override
  final StreamValue<bool> isAccountsPageLoadingStreamValue =
      StreamValue<bool>(defaultValue: false);

  @override
  final StreamValue<String?> accountsErrorStreamValue = StreamValue<String?>();

  @override
  Future<void> loadAccounts({
    int pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
  }) async {}

  @override
  Future<void> loadNextAccountsPage({
    int pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
  }) async {}

  @override
  void resetAccountsState() {}

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) async {
    fetchAccountBySlugCalls += 1;
    lastFetchedSlug = accountSlug;
    final account = _accountsById.values.firstWhere(
      (entry) => entry.slug == accountSlug,
      orElse: () => TenantAdminAccount(
        id: 'acc-1',
        name: 'Conta base',
        slug: accountSlug,
        document: const TenantAdminDocument(type: 'cpf', number: '000'),
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
    required int page,
    required int pageSize,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    return TenantAdminPagedAccountsResult(
      accounts: List<TenantAdminAccount>.unmodifiable(_accountsById.values),
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) async {
    final created = TenantAdminAccount(
      id: 'acc-created',
      name: name,
      slug: 'acc-created',
      document:
          document ?? const TenantAdminDocument(type: 'cpf', number: '001'),
      ownershipState: ownershipState,
      organizationId: organizationId,
    );
    _seedAccount(created);
    return created;
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
  }) async {
    final current = await fetchAccountBySlug(accountSlug);
    final updated = TenantAdminAccount(
      id: current.id,
      name: name ?? current.name,
      slug: slug ?? current.slug,
      document: document ?? current.document,
      ownershipState: current.ownershipState,
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
      TenantAdminAccount(
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
  Future<void> deleteAccount(String accountSlug) async {}

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) async {
    return fetchAccountBySlug(accountSlug);
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) async {}

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
  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async {
    if (accountId == null) {
      return const [];
    }
    return [
      TenantAdminAccountProfile(
        id: 'profile-1',
        accountId: accountId,
        profileType: 'artist',
        displayName: 'Perfil',
      ),
    ];
  }

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async {
    return const [
      TenantAdminProfileTypeDefinition(
        type: 'artist',
        label: 'Artist',
        allowedTaxonomies: [],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: true,
          isPoiEnabled: false,
          hasBio: true,
          hasContent: true,
          hasTaxonomies: true,
          hasAvatar: true,
          hasCover: true,
          hasEvents: true,
        ),
      ),
    ];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    final types = await fetchProfileTypes();
    return TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
      items: types,
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
    String accountProfileId,
  ) async {
    return const TenantAdminAccountProfile(
      id: 'profile-1',
      accountId: 'acc-1',
      profileType: 'artist',
      displayName: 'Perfil',
    );
  }

  @override
  Future<TenantAdminAccountProfile> createAccountProfile({
    required String accountId,
    required String profileType,
    required String displayName,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm> taxonomyTerms = const [],
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return TenantAdminAccountProfile(
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
    required String accountProfileId,
    String? profileType,
    String? displayName,
    String? slug,
    TenantAdminLocation? location,
    List<TenantAdminTaxonomyTerm>? taxonomyTerms,
    String? bio,
    String? content,
    String? avatarUrl,
    String? coverUrl,
    TenantAdminMediaUpload? avatarUpload,
    TenantAdminMediaUpload? coverUpload,
  }) async {
    return TenantAdminAccountProfile(
      id: accountProfileId,
      accountId: 'acc-1',
      profileType: profileType ?? 'artist',
      displayName: displayName ?? 'Perfil',
      slug: slug ?? 'perfil',
      location: location,
      taxonomyTerms: taxonomyTerms ?? const [],
      bio: bio,
      content: content,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
    String accountProfileId,
  ) async {
    return fetchAccountProfile(accountProfileId);
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: type,
      label: label,
      allowedTaxonomies: allowedTaxonomies,
      capabilities: capabilities,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) async {
    return TenantAdminProfileTypeDefinition(
      type: newType ?? type,
      label: label ?? 'Updated',
      allowedTaxonomies: allowedTaxonomies ?? const [],
      capabilities: capabilities ??
          const TenantAdminProfileTypeCapabilities(
            isFavoritable: true,
            isPoiEnabled: false,
            hasBio: true,
            hasContent: true,
            hasTaxonomies: true,
            hasAvatar: true,
            hasCover: true,
            hasEvents: true,
          ),
    );
  }

  @override
  Future<void> deleteProfileType(String type) async {}
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async {
    return const [];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyDefinition>>
      fetchTaxonomiesPage({
    required int page,
    required int pageSize,
  }) async {
    return const TenantAdminPagedResult<TenantAdminTaxonomyDefinition>(
      items: <TenantAdminTaxonomyDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) async {
    return TenantAdminTaxonomyDefinition(
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
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) async {
    return TenantAdminTaxonomyDefinition(
      id: taxonomyId,
      slug: slug ?? 'taxonomy',
      name: name ?? 'Taxonomy',
      appliesTo: appliesTo ?? const [],
      icon: icon,
      color: color,
    );
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {}

  @override
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async {
    return const [];
  }

  @override
  Future<TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>>
      fetchTermsPage({
    required String taxonomyId,
    required int page,
    required int pageSize,
  }) async {
    return const TenantAdminPagedResult<TenantAdminTaxonomyTermDefinition>(
      items: <TenantAdminTaxonomyTermDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) async {
    return TenantAdminTaxonomyTermDefinition(
      id: 'term-1',
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) async {
    return TenantAdminTaxonomyTermDefinition(
      id: termId,
      taxonomyId: taxonomyId,
      slug: slug ?? 'term',
      name: name ?? 'Term',
    );
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {}
}
