import 'dart:convert';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_accounts_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

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
  final List<RequestOptions> requests = [];

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
  }) {
    return {
      'id': id,
      'name': 'Conta $id',
      'slug': slug,
      'document': {
        'type': 'cpf',
        'number': '000$id',
      },
      'ownership_state': 'tenant_owned',
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
