import 'dart:convert';

import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_location.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
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

  test('createAccount preserves structured 422 validation failure', () async {
    final adapter = _AccountsCreateValidationAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    expect(
      repository.createAccount(
        name: '',
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
      throwsA(
        isA<FormValidationFailure>()
            .having((error) => error.message, 'message',
                'The given data was invalid.')
            .having(
          (error) => error.fieldErrors['name'],
          'name error',
          <String>['Nome e obrigatorio.'],
        ),
      ),
    );
  });

  test('createAccount surfaces structured 429 security failure', () async {
    final adapter = _AccountsCreateRateLimitedAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    expect(
      repository.createAccount(
        name: 'Conta',
        ownershipState: TenantAdminOwnershipState.tenantOwned,
      ),
      throwsA(
        isA<FormApiFailure>()
            .having((error) => error.statusCode, 'statusCode', 429)
            .having((error) => error.errorCode, 'errorCode', 'rate_limited')
            .having(
              (error) => error.retryAfterSeconds,
              'retryAfterSeconds',
              12,
            ),
      ),
    );
  });

  test('createAccountOnboarding calls onboarding endpoint and maps result',
      () async {
    final adapter = _AccountsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminAccountsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final result = await repository.createAccountOnboarding(
      name: 'Conta onboarding',
      ownershipState: TenantAdminOwnershipState.unmanaged,
      profileType: 'venue',
      location: const TenantAdminLocation(latitude: -20.31, longitude: -40.29),
      taxonomyTerms: const [
        TenantAdminTaxonomyTerm(type: 'genre', value: 'urbana'),
      ],
      bio: '<p>Bio</p>',
    );

    expect(result.account.name, 'Conta onboarding');
    expect(result.accountProfile.accountId, result.account.id);
    expect(result.accountProfile.profileType, 'venue');
    expect(adapter.requests.last.path, contains('/v1/account_onboardings'));
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

    if (options.path.endsWith('/v1/account_onboardings')) {
      return _jsonResponse({
        'data': {
          'account': _accountJson(
            id: 'onboarding-1',
            slug: 'acc-onboarding-1',
            ownershipState: 'unmanaged',
          )..['name'] = 'Conta onboarding',
          'account_profile': {
            'id': 'profile-onboarding-1',
            'account_id': 'onboarding-1',
            'profile_type': 'venue',
            'display_name': 'Conta onboarding',
            'location': {'lat': -20.31, 'lng': -40.29},
            'taxonomy_terms': [
              {'type': 'genre', 'value': 'urbana'}
            ],
            'ownership_state': 'unmanaged',
          },
          'role': {
            'id': 'role-1',
            'slug': 'admin',
          },
        },
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

class _AccountsCreateValidationAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'message': 'The given data was invalid.',
        'errors': {
          'name': ['Nome e obrigatorio.'],
        },
      }),
      422,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _AccountsCreateRateLimitedAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<dynamic>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'code': 'rate_limited',
        'message': 'Too many requests. Retry later.',
        'retry_after': 12,
        'correlation_id': 'corr-rate-1',
      }),
      429,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
