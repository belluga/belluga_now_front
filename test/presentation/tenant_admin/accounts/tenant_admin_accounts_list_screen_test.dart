import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_accounts_repository_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_onboarding_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_accounts_result.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_accounts_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_accounts_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

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
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester.pumpWidget(_buildTestApp(TenantAdminAccountsListScreen()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Nenhuma conta encontrada'), findsNothing);
  });

  testWidgets('shows empty state only when list is loaded and empty',
      (tester) async {
    final controller = TenantAdminAccountsController(
      accountsRepository: _FakeAccountsRepository(initialAccounts: []),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester.pumpWidget(_buildTestApp(TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma conta encontrada'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders loaded account card', (tester) async {
    final controller = TenantAdminAccountsController(
      accountsRepository: _FakeAccountsRepository(
        initialAccounts: [
          tenantAdminAccountFromRaw(
            id: 'acc-1',
            name: 'Conta 1',
            slug: 'conta-1',
            document: tenantAdminDocumentFromRaw(type: 'cpf', number: '0001'),
            ownershipState: TenantAdminOwnershipState.tenantOwned,
          ),
        ],
      ),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester.pumpWidget(_buildTestApp(TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Conta 1'), findsOneWidget);
  });

  testWidgets('unmanaged filter does not include user_owned accounts',
      (tester) async {
    final controller = TenantAdminAccountsController(
      accountsRepository: _FakeAccountsRepository(
        initialAccounts: [
          tenantAdminAccountFromRaw(
            id: 'acc-legacy',
            name: 'Conta Legacy',
            slug: 'conta-legacy',
            document: tenantAdminDocumentFromRaw(type: 'cpf', number: '1000'),
            ownershipState: TenantAdminOwnershipState.userOwned,
          ),
        ],
      ),
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester.pumpWidget(_buildTestApp(TenantAdminAccountsListScreen()));
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
        TenantAdminOwnershipState.tenantOwned: [],
        TenantAdminOwnershipState.unmanaged: [
          tenantAdminAccountFromRaw(
            id: 'acc-unmanaged',
            name: 'Conta unmanaged',
            slug: 'conta-unmanaged',
            document: tenantAdminDocumentFromRaw(type: 'cpf', number: '2222'),
            ownershipState: TenantAdminOwnershipState.unmanaged,
          ),
        ],
      },
    );
    final controller = TenantAdminAccountsController(
      accountsRepository: repository,
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester.pumpWidget(_buildTestApp(TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Conta unmanaged'), findsNothing);
    expect(
      repository.loadAccountsOwnershipCalls.last,
      TenantAdminOwnershipState.tenantOwned,
    );

    await tester.tap(find.text('Nao gerenciadas'));
    await tester.pumpAndSettle();

    expect(find.text('Conta unmanaged'), findsOneWidget);
    expect(
      repository.loadAccountsOwnershipCalls.last,
      TenantAdminOwnershipState.unmanaged,
    );
  });

  testWidgets('search field triggers backend-first reload with query',
      (tester) async {
    final repository = _FakeAccountsRepository(
      initialAccounts: [
        tenantAdminAccountFromRaw(
          id: 'acc-1',
          name: 'Conta Alpha',
          slug: 'conta-alpha',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '1001'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
        tenantAdminAccountFromRaw(
          id: 'acc-2',
          name: 'Conta Beta',
          slug: 'conta-beta',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '1002'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ],
    );
    final controller = TenantAdminAccountsController(
      accountsRepository: repository,
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester.pumpWidget(_buildTestApp(TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('tenant_admin_accounts_search_toggle'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(
        const ValueKey<String>('tenant_admin_accounts_search_field'),
      ),
      'Beta',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repository.loadAccountsSearchCalls.last, 'Beta');
    expect(find.text('Conta Beta'), findsOneWidget);
    expect(find.text('Conta Alpha'), findsNothing);
  });

  testWidgets('reloads list when returning from account detail route',
      (tester) async {
    final repository = _FakeAccountsRepository(
      initialAccounts: [
        tenantAdminAccountFromRaw(
          id: 'acc-1',
          name: 'Conta 1',
          slug: 'conta-1',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '0001'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ],
    );
    final controller = TenantAdminAccountsController(
      accountsRepository: repository,
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester.pumpWidget(_buildTestApp(TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(repository.loadAccountsOwnershipCalls, hasLength(1));

    await tester.tap(
        find.byKey(const ValueKey<String>('tenant_admin_account_card_acc-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('account_detail_close')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('account_detail_close')));
    await tester.pumpAndSettle();

    expect(repository.loadAccountsOwnershipCalls, hasLength(2));
  });

  testWidgets('reloads list after successful account create return',
      (tester) async {
    final repository = _FakeAccountsRepository(
      initialAccounts: [
        tenantAdminAccountFromRaw(
          id: 'acc-1',
          name: 'Conta 1',
          slug: 'conta-1',
          document: tenantAdminDocumentFromRaw(type: 'cpf', number: '0001'),
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
      ],
    );
    final controller = TenantAdminAccountsController(
      accountsRepository: repository,
    );
    GetIt.I.registerSingleton<TenantAdminAccountsController>(controller);

    await tester.pumpWidget(_buildTestApp(TenantAdminAccountsListScreen()));
    await tester.pumpAndSettle();

    expect(repository.loadAccountsOwnershipCalls, hasLength(1));

    await tester.tap(find.text('Criar conta'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey<String>('account_create_success')),
        findsOneWidget);

    await tester
        .tap(find.byKey(const ValueKey<String>('account_create_success')));
    await tester.pumpAndSettle();

    expect(repository.loadAccountsOwnershipCalls, hasLength(2));
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
      NamedRouteDef(
        name: TenantAdminAccountDetailRoute.name,
        path: '/accounts/:accountSlug',
        builder: (_, __) => const _TestAccountDetailRouteScreen(),
      ),
      NamedRouteDef(
        name: TenantAdminAccountCreateRoute.name,
        path: '/accounts/create',
        builder: (_, __) => const _TestAccountCreateRouteScreen(),
      ),
    ],
  )..ignorePopCompleters = true;

  return MaterialApp.router(
    routeInformationParser: router.defaultRouteParser(),
    routerDelegate: router.delegate(),
  );
}

class _TestAccountDetailRouteScreen extends StatelessWidget {
  const _TestAccountDetailRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('account_detail_close'),
          onPressed: () => context.router.maybePop(),
          child: const Text('Voltar'),
        ),
      ),
    );
  }
}

class _TestAccountCreateRouteScreen extends StatelessWidget {
  const _TestAccountCreateRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('account_create_success'),
          onPressed: () => context.router.maybePop(true),
          child: const Text('Salvar'),
        ),
      ),
    );
  }
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
      hasMoreAccountsStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
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
  final List<String?> loadAccountsSearchCalls = <String?>[];

  @override
  Future<void> loadAccounts({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    loadAccountsOwnershipCalls.add(ownershipState);
    loadAccountsSearchCalls.add(searchQuery?.value);
    final selectedAccounts = _selectedAccounts(
      ownershipState,
      searchQuery: searchQuery?.value,
    );
    if (selectedAccounts != null) {
      accountsStreamValue
          .addValue(List<TenantAdminAccount>.from(selectedAccounts));
      hasMoreAccountsStreamValue.addValue(
        TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
          false,
          defaultValue: false,
        ),
      );
      accountsErrorStreamValue.addValue(null);
      return;
    }
    if (initialAccounts == null) {
      accountsStreamValue.addValue(null);
      return;
    }
    accountsStreamValue
        .addValue(List<TenantAdminAccount>.from(initialAccounts!));
    hasMoreAccountsStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
    accountsErrorStreamValue.addValue(null);
  }

  @override
  Future<void> loadNextAccountsPage({
    TenantAdminAccountsRepositoryContractPrimInt? pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {}

  @override
  void resetAccountsState() {
    accountsStreamValue.addValue(null);
    hasMoreAccountsStreamValue.addValue(
      TenantAdminAccountsRepositoryContractPrimBool.fromRaw(
        false,
        defaultValue: false,
      ),
    );
    accountsErrorStreamValue.addValue(null);
  }

  @override
  Future<List<TenantAdminAccount>> fetchAccounts() async =>
      List<TenantAdminAccount>.from(initialAccounts ?? []);

  @override
  Future<TenantAdminPagedAccountsResult> fetchAccountsPage({
    required TenantAdminAccountsRepositoryContractPrimInt page,
    required TenantAdminAccountsRepositoryContractPrimInt pageSize,
    TenantAdminOwnershipState? ownershipState,
    TenantAdminAccountsRepositoryContractPrimString? searchQuery,
  }) async {
    final selectedAccounts = _selectedAccounts(
      ownershipState,
      searchQuery: searchQuery?.value,
    );
    final accounts = List<TenantAdminAccount>.from(
      selectedAccounts ?? initialAccounts ?? [],
    );
    final start = (page.value - 1) * pageSize.value;
    if (start >= accounts.length || page.value <= 0 || pageSize.value <= 0) {
      return tenantAdminPagedAccountsResultFromRaw(
        accounts: <TenantAdminAccount>[],
        hasMore: false,
      );
    }
    final end = (start + pageSize.value) < accounts.length
        ? (start + pageSize.value)
        : accounts.length;
    return tenantAdminPagedAccountsResultFromRaw(
      accounts: accounts.sublist(start, end),
      hasMore: end < accounts.length,
    );
  }

  @override
  Future<TenantAdminAccount> fetchAccountBySlug(
      TenantAdminAccountsRepositoryContractPrimString accountSlug) {
    throw UnimplementedError();
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
      TenantAdminAccountsRepositoryContractPrimString accountSlug) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminAccount> restoreAccount(
      TenantAdminAccountsRepositoryContractPrimString accountSlug) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteAccount(
      TenantAdminAccountsRepositoryContractPrimString accountSlug) {
    throw UnimplementedError();
  }

  List<TenantAdminAccount>? _selectedAccounts(
    TenantAdminOwnershipState? ownershipState, {
    String? searchQuery,
  }) {
    final normalizedSearch = searchQuery?.trim().toLowerCase() ?? '';
    final source = accountsByOwnership.isEmpty
        ? (initialAccounts == null
            ? null
            : List<TenantAdminAccount>.from(initialAccounts!))
        : List<TenantAdminAccount>.from(
            accountsByOwnership[
                    ownershipState ?? TenantAdminOwnershipState.tenantOwned] ??
                <TenantAdminAccount>[],
          );
    if (source == null || normalizedSearch.isEmpty) {
      return source;
    }
    return source.where((account) {
      return account.name.toLowerCase().contains(normalizedSearch) ||
          account.slug.toLowerCase().contains(normalizedSearch) ||
          account.document.number.toLowerCase().contains(normalizedSearch);
    }).toList(growable: false);
  }
}
