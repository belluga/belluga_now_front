import 'dart:convert';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_accounts_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/tenant_admin_paged_stream_contract.dart';

void main() {
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(_StubAuthRepo());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('fetchAccountsPage sends pagination params and parses hasMore',
      () async {
    final adapter = _AccountsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final page = await repository.fetchAccountsPage(page: 1, pageSize: 2);

    expect(page.accounts, hasLength(2));
    expect(page.hasMore, isTrue);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.single.queryParameters['page'], 1);
    expect(adapter.requests.single.queryParameters['page_size'], 2);
  });

  test('fetchAccountsPage sends ownership_state filter when provided',
      () async {
    final adapter = _AccountsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final page = await repository.fetchAccountsPage(
      page: 1,
      pageSize: 2,
      ownershipState: TenantAdminOwnershipState.unmanaged,
    );

    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.queryParameters['ownership_state'],
      'unmanaged',
    );
    expect(page.accounts, hasLength(1));
    expect(page.accounts.single.slug, 'acc-u1');
  });

  test('fetchAccounts aggregates all pages', () async {
    final adapter = _AccountsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final accounts = await repository.fetchAccounts();

    expect(accounts, hasLength(3));
    expect(accounts.first.slug, 'acc-1');
    expect(accounts.last.slug, 'acc-3');
    expect(adapter.requests, hasLength(2));
  });

  test('fetchAccountsPage maps missing ownership_state to unmanaged', () async {
    final adapter = _AccountsRoutingAdapter(includeOwnershipState: false);
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final page = await repository.fetchAccountsPage(page: 1, pageSize: 2);

    expect(page.accounts, isNotEmpty);
    expect(
      page.accounts
          .every((account) => account.ownershipState.apiValue == 'unmanaged'),
      isTrue,
    );
  });

  test(
      'loadAccounts publishes existing accounts even when ownership_state is missing',
      () async {
    final adapter = _AccountsRoutingAdapter(includeOwnershipState: false);
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.loadAccounts(pageSize: 2);

    final loaded = repository.accountsStreamValue.value;
    expect(loaded, isNotNull);
    expect(loaded, hasLength(2));
    expect(loaded!.first.slug, 'acc-1');
  });

  test('load/reset/next follow paged stream contract', () async {
    final adapter = _AccountsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await verifyTenantAdminPagedStreamContract(
      scope: 'accounts',
      loadFirstPage: () => repository.loadAccounts(pageSize: 2),
      loadNextPage: () => repository.loadNextAccountsPage(pageSize: 2),
      resetState: repository.resetAccountsState,
      readItems: () => repository.accountsStreamValue.value,
      readHasMore: () => repository.hasMoreAccountsStreamValue.value,
      readError: () => repository.accountsErrorStreamValue.value,
      expectedCountsPerStep: const [2, 3],
      loadNextCalls: 1,
    );
  });

  test('loadAccounts resets pagination when ownership filter changes',
      () async {
    final adapter = _AccountsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.loadAccounts(
      pageSize: 2,
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
    expect(repository.accountsStreamValue.value, hasLength(2));

    await repository.loadAccounts(
      pageSize: 2,
      ownershipState: TenantAdminOwnershipState.unmanaged,
    );

    final loaded = repository.accountsStreamValue.value;
    expect(loaded, hasLength(1));
    expect(loaded!.single.slug, 'acc-u1');
    expect(
      adapter.requests.last.queryParameters['ownership_state'],
      'unmanaged',
    );
    expect(adapter.requests.last.queryParameters['page'], 1);
  });

  test('loadAccounts refetches first page when returning to a previous filter',
      () async {
    final adapter = _AccountsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.loadAccounts(
      pageSize: 2,
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
    expect(adapter.requests.length, 1);

    await repository.loadAccounts(
      pageSize: 2,
      ownershipState: TenantAdminOwnershipState.unmanaged,
    );
    expect(adapter.requests.length, 2);

    await repository.loadAccounts(
      pageSize: 2,
      ownershipState: TenantAdminOwnershipState.tenantOwned,
    );
    expect(adapter.requests.length, 3);
    expect(
      repository.accountsStreamValue.value!.map((account) => account.slug),
      containsAll(['acc-1', 'acc-2']),
    );
  });

  test('fetchAccountsPage still fails on unknown ownership_state value',
      () async {
    final adapter =
        _AccountsRoutingAdapter(ownershipStateValue: 'broken_state');
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    expect(
      repository.fetchAccountsPage(
        page: 1,
        pageSize: 2,
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.toString(),
          'message',
          contains('Invalid ownership_state value'),
        ),
      ),
    );
  });
}

class _StubAuthRepo implements LandlordAuthRepositoryContract {
  @override
  bool get hasValidSession => true;

  @override
  String get token => 'test-token';

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> logout() async {}
}

class _MutableTenantScope implements TenantAdminTenantScopeContract {
  _MutableTenantScope(String initialBaseUrl) {
    _selectedTenantDomainStreamValue.addValue(initialBaseUrl);
  }

  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl => selectedTenantDomain ?? '';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
  }
}

class _AccountsRoutingAdapter implements HttpClientAdapter {
  _AccountsRoutingAdapter({
    this.includeOwnershipState = true,
    this.ownershipStateValue = 'tenant_owned',
  });

  final List<RequestOptions> requests = [];
  final bool includeOwnershipState;
  final String ownershipStateValue;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    requests.add(options);
    final page = (options.queryParameters['page'] as int?) ?? 1;
    final ownershipState =
        options.queryParameters['ownership_state'] as String?;

    if (options.path.endsWith('/v1/accounts') &&
        ownershipState == 'unmanaged' &&
        page == 1) {
      return _jsonResponse({
        'data': [
          _accountJson(
            id: 'u1',
            slug: 'acc-u1',
            ownershipState: 'unmanaged',
          ),
        ],
        'current_page': 1,
        'last_page': 1,
      });
    }

    if (options.path.endsWith('/v1/accounts') &&
        ownershipState == 'tenant_owned' &&
        page == 1) {
      return _jsonResponse({
        'data': [
          _accountJson(
            id: '1',
            slug: 'acc-1',
            ownershipState: ownershipStateValue,
          ),
          _accountJson(
            id: '2',
            slug: 'acc-2',
            ownershipState: ownershipStateValue,
          ),
        ],
        'current_page': 1,
        'last_page': 1,
      });
    }

    if (options.path.endsWith('/v1/accounts') && page == 1) {
      return _jsonResponse({
        'data': [
          _accountJson(id: '1', slug: 'acc-1'),
          _accountJson(id: '2', slug: 'acc-2'),
        ],
        'current_page': 1,
        'last_page': 2,
      });
    }

    if (options.path.endsWith('/v1/accounts') && page == 2) {
      return _jsonResponse({
        'data': [
          _accountJson(id: '3', slug: 'acc-3'),
        ],
        'current_page': 2,
        'last_page': 2,
      });
    }

    return _jsonResponse({
      'data': const [],
      'current_page': page,
      'last_page': page,
    });
  }

  Map<String, dynamic> _accountJson({
    required String id,
    required String slug,
    String? ownershipState,
  }) {
    return {
      'id': id,
      'name': 'Conta $id',
      'slug': slug,
      'document': {
        'type': 'cpf',
        'number': '000$id',
      },
      if (includeOwnershipState)
        'ownership_state': ownershipState ?? ownershipStateValue,
    };
  }

  ResponseBody _jsonResponse(Map<String, dynamic> payload) {
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
