import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/controllers/tenant_admin_account_profiles_list_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_accounts_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('shows loading state while profiles page is pending', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository();
    repository.pageGate = Completer<void>();
    _register(repository);

    await tester.pumpWidget(
      _buildTestApp(const TenantAdminAccountsListScreen()),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Nenhum perfil encontrado'), findsNothing);
    repository.pageGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('shows empty state only when profile page is loaded empty', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository();
    _register(repository);

    await tester.pumpWidget(
      _buildTestApp(const TenantAdminAccountsListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhum perfil encontrado'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders profile rows without ownership filter controls', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository(
      profiles: [
        _profile(
          id: 'profile-1',
          displayName: 'Casa João Silva',
          accountSlug: 'casa-joao-silva',
        ),
      ],
    );
    _register(repository);

    await tester.pumpWidget(
      _buildTestApp(const TenantAdminAccountsListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Casa João Silva'), findsOneWidget);
    expect(find.text('venue'), findsOneWidget);
    expect(find.byType(SegmentedButton<Object>), findsNothing);
    expect(find.text('Nome, slug ou documento'), findsNothing);
    expect(repository.requests.single.search, isNull);
  });

  testWidgets('search reloads through the Account Profile repository', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository(
      profiles: [
        _profile(id: 'profile-alpha', displayName: 'Casa Alpha'),
        _profile(id: 'profile-beta', displayName: 'Casa Beta'),
      ],
    );
    _register(repository);

    await tester.pumpWidget(
      _buildTestApp(const TenantAdminAccountsListScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('tenant_admin_accounts_search_toggle')),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey<String>('tenant_admin_accounts_search_field')),
      'Beta',
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(repository.requests.last.search, 'Beta');
    expect(find.text('Casa Beta'), findsOneWidget);
  });

  testWidgets('refreshes after returning from profile edit route', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository(
      profiles: [_profile(id: 'profile-1', accountSlug: 'account-1')],
    );
    _register(repository);

    await tester.pumpWidget(
      _buildTestApp(const TenantAdminAccountsListScreen()),
    );
    await tester.pumpAndSettle();
    expect(repository.requests, hasLength(1));

    await tester.tap(
      find.byKey(
        const ValueKey<String>('tenant_admin_account_profile_card_profile-1'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('profile_edit_close')));
    await tester.pumpAndSettle();

    expect(repository.requests, hasLength(2));
  });

  testWidgets('edit authority fails closed from Profile ownership metadata', (
    tester,
  ) async {
    final repository = _FakeProfilesRepository(
      profiles: [
        _profile(
          id: 'tenant-owned',
          accountSlug: 'tenant-owned',
          ownershipState: TenantAdminOwnershipState.tenantOwned,
        ),
        _profile(
          id: 'unmanaged',
          accountSlug: 'unmanaged',
          ownershipState: TenantAdminOwnershipState.unmanaged,
        ),
        _profile(
          id: 'user-owned',
          accountSlug: 'user-owned',
          ownershipState: TenantAdminOwnershipState.userOwned,
        ),
        _profile(id: 'unknown', accountSlug: 'unknown', ownershipState: null),
      ],
    );
    _register(repository);

    await tester.pumpWidget(
      _buildTestApp(const TenantAdminAccountsListScreen()),
    );
    await tester.pumpAndSettle();

    InkWell row(String id) => tester.widget<InkWell>(
      find.byKey(ValueKey<String>('tenant_admin_account_profile_card_$id')),
    );

    expect(row('tenant-owned').onTap, isNotNull);
    expect(row('unmanaged').onTap, isNotNull);
    expect(row('user-owned').onTap, isNull);
    expect(row('unknown').onTap, isNull);
  });

  test(
    'loads the next Profile page without walking or filtering locally',
    () async {
      final repository = _FakeProfilesRepository(
        profiles: [_profile(id: 'profile-1')],
        pageResults: [
          tenantAdminPagedResultFromRaw(
            items: [_profile(id: 'profile-1')],
            hasMore: true,
            currentPage: 1,
            pageSize: 20,
          ),
          tenantAdminPagedResultFromRaw(
            items: [_profile(id: 'profile-2')],
            hasMore: false,
            currentPage: 2,
            pageSize: 20,
          ),
        ],
      );
      final controller = TenantAdminAccountProfilesListController(
        profilesRepository: repository,
      );

      await controller.init();
      await controller.loadNextProfilesPage();

      expect(repository.requests.map((request) => request.page).toList(), [
        1,
        2,
      ]);
      expect(
        controller.profilesStreamValue.value
            ?.map((profile) => profile.id)
            .toList(),
        ['profile-1', 'profile-2'],
      );
      controller.dispose();
    },
  );

  test(
    'keeps the newest search result when an older request finishes last',
    () async {
      final repository = _ControlledProfilesRepository();
      final controller = TenantAdminAccountProfilesListController(
        profilesRepository: repository,
      );

      final older = controller.loadProfiles(searchQuery: 'Alpha');
      final newer = controller.loadProfiles(searchQuery: 'Beta');
      repository.complete(
        'Beta',
        tenantAdminPagedResultFromRaw(
          items: [_profile(id: 'profile-beta', displayName: 'Casa Beta')],
          hasMore: false,
          currentPage: 1,
          pageSize: 20,
        ),
      );
      await newer;
      repository.complete(
        'Alpha',
        tenantAdminPagedResultFromRaw(
          items: [_profile(id: 'profile-alpha', displayName: 'Casa Alpha')],
          hasMore: false,
          currentPage: 1,
          pageSize: 20,
        ),
      );
      await older;

      expect(
        controller.profilesStreamValue.value?.map((profile) => profile.id),
        ['profile-beta'],
      );
      controller.dispose();
    },
  );

  test(
    'drops a duplicate load-more request while one page is pending',
    () async {
      final repository = _FakeProfilesRepository(
        pageResults: [
          tenantAdminPagedResultFromRaw(
            items: [_profile(id: 'profile-1')],
            hasMore: true,
            currentPage: 1,
            pageSize: 20,
          ),
          tenantAdminPagedResultFromRaw(
            items: [_profile(id: 'profile-2')],
            hasMore: false,
            currentPage: 2,
            pageSize: 20,
          ),
        ],
      );
      final controller = TenantAdminAccountProfilesListController(
        profilesRepository: repository,
      );
      await controller.init();
      repository.pageGate = Completer<void>();

      final first = controller.loadNextProfilesPage();
      final duplicate = controller.loadNextProfilesPage();
      expect(repository.requests.map((request) => request.page), [1, 2]);
      repository.pageGate!.complete();
      await Future.wait([first, duplicate]);

      expect(
        controller.profilesStreamValue.value?.map((profile) => profile.id),
        ['profile-1', 'profile-2'],
      );
      controller.dispose();
    },
  );

  test(
    'reloads and clears the previous page when the tenant changes',
    () async {
      final repository = _FakeProfilesRepository(
        profiles: [_profile(id: 'profile-1')],
      );
      final tenantScope = _MutableTenantScope('tenant-a.test');
      final controller = TenantAdminAccountProfilesListController(
        profilesRepository: repository,
        tenantScope: tenantScope,
      );
      await controller.init();

      tenantScope.selectTenantDomain('tenant-b.test');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.requests, hasLength(2));
      expect(controller.profilesStreamValue.value?.single.id, 'profile-1');
      controller.dispose();
      tenantScope.dispose();
    },
  );
}

void _register(_FakeProfilesRepository repository) {
  GetIt.I.registerLazySingleton<TenantAdminAccountProfilesListController>(
    () => TenantAdminAccountProfilesListController(
      profilesRepository: repository,
    ),
  );
}

Widget _buildTestApp(Widget child) {
  final router = RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'accounts-list-test',
        path: '/',
        builder: (_, _) => child,
      ),
      NamedRouteDef(
        name: TenantAdminAccountProfileEditRoute.name,
        path: '/accounts/:accountSlug/profiles/:accountProfileId/edit',
        builder: (_, _) => const _TestProfileEditRouteScreen(),
      ),
    ],
  )..ignorePopCompleters = true;

  return MaterialApp.router(
    routeInformationParser: router.defaultRouteParser(),
    routerDelegate: router.delegate(),
  );
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

class _ProfileRequest {
  const _ProfileRequest({required this.page, this.search});

  final int page;
  final String? search;
}

class _FakeProfilesRepository extends Mock
    implements TenantAdminAccountProfilesRepositoryContract {
  _FakeProfilesRepository({
    List<TenantAdminAccountProfile>? profiles,
    this.pageResults = const [],
  }) : profiles = profiles ?? const [];

  final List<TenantAdminAccountProfile> profiles;
  final List<TenantAdminPagedResult<TenantAdminAccountProfile>> pageResults;
  final List<_ProfileRequest> requests = <_ProfileRequest>[];
  Completer<void>? pageGate;

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? search,
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoString? profileType,
  }) async {
    return _loadPage(page.value, search?.value, pageSize: pageSize.value);
  }

  Future<TenantAdminPagedResult<TenantAdminAccountProfile>> _loadPage(
    int page,
    String? search, {
    int pageSize = 20,
  }) async {
    requests.add(_ProfileRequest(page: page, search: search));
    await pageGate?.future;
    if (page > 0 && page <= pageResults.length) {
      return pageResults[page - 1];
    }
    final query = search?.trim().toLowerCase() ?? '';
    final filtered = query.isEmpty
        ? profiles
        : profiles
              .where(
                (profile) => profile.displayName.toLowerCase().contains(query),
              )
              .toList(growable: false);
    return tenantAdminPagedResultFromRaw(
      items: filtered,
      hasMore: false,
      currentPage: page,
      pageSize: pageSize,
    );
  }
}

class _ControlledProfilesRepository extends Mock
    implements TenantAdminAccountProfilesRepositoryContract {
  final Map<
    String,
    Completer<TenantAdminPagedResult<TenantAdminAccountProfile>>
  >
  _requests = {};

  @override
  Future<TenantAdminPagedResult<TenantAdminAccountProfile>>
  fetchAccountProfilesPage({
    required TenantAdminAccountProfilesRepoInt page,
    required TenantAdminAccountProfilesRepoInt pageSize,
    TenantAdminAccountProfilesRepoString? search,
    TenantAdminAccountProfilesRepoString? accountId,
    TenantAdminAccountProfilesRepoString? profileType,
  }) {
    final key = search?.value ?? '';
    final completer =
        Completer<TenantAdminPagedResult<TenantAdminAccountProfile>>();
    _requests[key] = completer;
    return completer.future;
  }

  void complete(
    String search,
    TenantAdminPagedResult<TenantAdminAccountProfile> result,
  ) {
    _requests[search]!.complete(result);
  }
}

class _MutableTenantScope implements TenantAdminTenantScopeContract {
  _MutableTenantScope(String initialDomain) {
    selectedTenantDomainStreamValue.addValue(initialDomain);
  }

  @override
  final StreamValue<String?> selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl =>
      'https://${selectedTenantDomain ?? ''}/admin/api';

  @override
  void clearSelectedTenantDomain() {
    selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    selectedTenantDomainStreamValue.addValue(tenantDomain.toString());
  }

  void dispose() => selectedTenantDomainStreamValue.dispose();
}

TenantAdminAccountProfile _profile({
  required String id,
  String displayName = 'Perfil',
  String? accountSlug,
  TenantAdminOwnershipState? ownershipState =
      TenantAdminOwnershipState.tenantOwned,
}) {
  return tenantAdminAccountProfileFromRaw(
    id: id,
    accountId: 'account-$id',
    accountSlug: accountSlug,
    profileType: 'venue',
    displayName: displayName,
    ownershipState: ownershipState,
  );
}
