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
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_location_selection_service.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_accounts_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('shows loading state while accounts stream is null',
      (tester) async {
    final controller = TenantAdminAccountsController(
      accountsRepository: _FakeAccountsRepository(
        initialAccounts: null,
      ),
      profilesRepository: _FakeProfilesRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester
        .pumpWidget(_buildTestApp(const TenantAdminAccountsListScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Nenhuma conta encontrada'), findsNothing);
  });

  testWidgets('shows empty state only when list is loaded and empty',
      (tester) async {
    final controller = TenantAdminAccountsController(
      accountsRepository: _FakeAccountsRepository(initialAccounts: const []),
      profilesRepository: _FakeProfilesRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester
        .pumpWidget(_buildTestApp(const TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma conta encontrada'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders loaded account card', (tester) async {
    final controller = TenantAdminAccountsController(
      accountsRepository: _FakeAccountsRepository(
        initialAccounts: const [
          TenantAdminAccount(
            id: 'acc-1',
            name: 'Conta 1',
            slug: 'conta-1',
            document: TenantAdminDocument(type: 'cpf', number: '0001'),
            ownershipState: TenantAdminOwnershipState.tenantOwned,
          ),
        ],
      ),
      profilesRepository: _FakeProfilesRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester
        .pumpWidget(_buildTestApp(const TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('conta-1'), findsOneWidget);
  });

  testWidgets('unmanaged filter does not include user_owned accounts',
      (tester) async {
    final controller = TenantAdminAccountsController(
      accountsRepository: _FakeAccountsRepository(
        initialAccounts: const [
          TenantAdminAccount(
            id: 'acc-legacy',
            name: 'Conta Legacy',
            slug: 'conta-legacy',
            document: TenantAdminDocument(type: 'cpf', number: '1000'),
            ownershipState: TenantAdminOwnershipState.userOwned,
          ),
        ],
      ),
      profilesRepository: _FakeProfilesRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester
        .pumpWidget(_buildTestApp(const TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('conta-legacy'), findsNothing);

    await tester.tap(find.text('Nao gerenciadas'));
    await tester.pumpAndSettle();

    expect(find.text('conta-legacy'), findsNothing);
  });

  testWidgets('segment switch reloads with backend ownership filter',
      (tester) async {
    final repository = _FakeAccountsRepository.byOwnership(
      accountsByOwnership: {
        TenantAdminOwnershipState.tenantOwned: const [],
        TenantAdminOwnershipState.unmanaged: const [
          TenantAdminAccount(
            id: 'acc-unmanaged',
            name: 'Conta unmanaged',
            slug: 'conta-unmanaged',
            document: TenantAdminDocument(type: 'cpf', number: '2222'),
            ownershipState: TenantAdminOwnershipState.unmanaged,
          ),
        ],
      },
    );
    final controller = TenantAdminAccountsController(
      accountsRepository: repository,
      profilesRepository: _FakeProfilesRepository(),
      taxonomiesRepository: _FakeTaxonomiesRepository(),
      locationSelectionService: TenantAdminLocationSelectionService(),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester
        .pumpWidget(_buildTestApp(const TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('conta-unmanaged'), findsNothing);
    expect(
      repository.loadAccountsOwnershipCalls.last,
      TenantAdminOwnershipState.tenantOwned,
    );

    await tester.tap(find.text('Nao gerenciadas'));
    await tester.pumpAndSettle();

    expect(find.text('conta-unmanaged'), findsOneWidget);
    expect(
      repository.loadAccountsOwnershipCalls.last,
      TenantAdminOwnershipState.unmanaged,
    );
  });
}

Widget _buildTestApp(Widget child) {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'accounts-list-test',
        path: '/',
        builder: (_, __) => child,
      ),
    ],
  )..ignorePopCompleters = true;

  return MaterialApp.router(
    routeInformationParser: router.defaultRouteParser(),
    routerDelegate: router.delegate(),
  );
}

class _FakeAccountsRepository
    with TenantAdminAccountsRepositoryPaginationMixin
    implements TenantAdminAccountsRepositoryContract {
  _FakeAccountsRepository({
    required this.initialAccounts,
  }) : accountsByOwnership = const {} {
    if (initialAccounts != null) {
      accountsStreamValue
          .addValue(List<TenantAdminAccount>.from(initialAccounts!));
      hasMoreAccountsStreamValue.addValue(false);
    }
  }

  _FakeAccountsRepository.byOwnership({
    required this.accountsByOwnership,
  }) : initialAccounts = null;

  final List<TenantAdminAccount>? initialAccounts;
  final Map<TenantAdminOwnershipState, List<TenantAdminAccount>>
      accountsByOwnership;
  final List<TenantAdminOwnershipState?> loadAccountsOwnershipCalls =
      <TenantAdminOwnershipState?>[];

  @override
  Future<void> loadAccounts({
    int pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    loadAccountsOwnershipCalls.add(ownershipState);
    final selectedAccounts = _selectedAccounts(ownershipState);
    if (selectedAccounts != null) {
      accountsStreamValue
          .addValue(List<TenantAdminAccount>.from(selectedAccounts));
      hasMoreAccountsStreamValue.addValue(false);
      accountsErrorStreamValue.addValue(null);
      return;
    }
    if (initialAccounts == null) {
      accountsStreamValue.addValue(null);
      return;
    }
    accountsStreamValue
        .addValue(List<TenantAdminAccount>.from(initialAccounts!));
    hasMoreAccountsStreamValue.addValue(false);
    accountsErrorStreamValue.addValue(null);
  }

  @override
  Future<void> loadNextAccountsPage({
    int pageSize = 20,
    TenantAdminOwnershipState? ownershipState,
  }) async {}

  @override
  void resetAccountsState() {
    accountsStreamValue.addValue(null);
    hasMoreAccountsStreamValue.addValue(false);
    accountsErrorStreamValue.addValue(null);
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async =>
      List<TenantAdminAccount>.from(initialAccounts ?? const []);

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required int page,
    required int pageSize,
    TenantAdminOwnershipState? ownershipState,
  }) async {
    final selectedAccounts = _selectedAccounts(ownershipState);
    final accounts = List<TenantAdminAccount>.from(
      selectedAccounts ?? initialAccounts ?? const [],
    );
    final start = (page - 1) * pageSize;
    if (start >= accounts.length || page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedAccountsResult(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final end = (start + pageSize) < accounts.length
        ? (start + pageSize)
        : accounts.length;
    return TenantAdminPagedAccountsResult(
      accounts: accounts.sublist(start, end),
      hasMore: end < accounts.length,
    );
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(String accountSlug) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> createAccount({
    required String name,
    TenantAdminDocument? document,
    required TenantAdminOwnershipState ownershipState,
    String? organizationId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> updateAccount({
    required String accountSlug,
    String? name,
    String? slug,
    TenantAdminDocument? document,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccount(String accountSlug) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> restoreAccount(String accountSlug) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccount(String accountSlug) {
    throw UnimplementedError();
  }

  List<TenantAdminAccount>? _selectedAccounts(
    TenantAdminOwnershipState? ownershipState,
  ) {
    if (accountsByOwnership.isEmpty) {
      return null;
    }
    final selected = ownershipState ?? TenantAdminOwnershipState.tenantOwned;
    return accountsByOwnership[selected] ?? const <TenantAdminAccount>[];
  }
}

class _FakeProfilesRepository
    with TenantAdminProfileTypesPaginationMixin
    implements TenantAdminAccountProfilesRepositoryContract {
  @override
  Future<List<TenantAdminAccountProfile>> fetchAccountProfiles({
    String? accountId,
  }) async =>
      const [];

  @override
  Future<TenantAdminAccountProfile> fetchAccountProfile(
      String accountProfileId) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAccountProfile(String accountProfileId) async {}

  @override
  Future<TenantAdminAccountProfile> restoreAccountProfile(
      String accountProfileId) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccountProfile(String accountProfileId) async {}

  @override
  Future<List<TenantAdminProfileTypeDefinition>> fetchProfileTypes() async =>
      const [];

  @override
  Future<TenantAdminPagedResult<TenantAdminProfileTypeDefinition>>
      fetchProfileTypesPage({
    required int page,
    required int pageSize,
  }) async {
    return const TenantAdminPagedResult<TenantAdminProfileTypeDefinition>(
      items: <TenantAdminProfileTypeDefinition>[],
      hasMore: false,
    );
  }

  @override
  Future<TenantAdminProfileTypeDefinition> createProfileType({
    required String type,
    required String label,
    List<String> allowedTaxonomies = const [],
    required TenantAdminProfileTypeCapabilities capabilities,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminProfileTypeDefinition> updateProfileType({
    required String type,
    String? newType,
    String? label,
    List<String>? allowedTaxonomies,
    TenantAdminProfileTypeCapabilities? capabilities,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteProfileType(String type) async {}
}

class _FakeTaxonomiesRepository
    with TenantAdminTaxonomiesPaginationMixin
    implements TenantAdminTaxonomiesRepositoryContract {
  @override
  Future<List<TenantAdminTaxonomyDefinition>> fetchTaxonomies() async =>
      const [];

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
  Future<List<TenantAdminTaxonomyTermDefinition>> fetchTerms({
    required String taxonomyId,
  }) async =>
      const [];

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
  Future<TenantAdminTaxonomyDefinition> createTaxonomy({
    required String slug,
    required String name,
    required List<String> appliesTo,
    String? icon,
    String? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyDefinition> updateTaxonomy({
    required String taxonomyId,
    String? slug,
    String? name,
    List<String>? appliesTo,
    String? icon,
    String? color,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTaxonomy(String taxonomyId) async {}

  @override
  Future<TenantAdminTaxonomyTermDefinition> createTerm({
    required String taxonomyId,
    required String slug,
    required String name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminTaxonomyTermDefinition> updateTerm({
    required String taxonomyId,
    required String termId,
    String? slug,
    String? name,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTerm({
    required String taxonomyId,
    required String termId,
  }) async {}
}
