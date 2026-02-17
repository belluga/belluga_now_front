import 'dart:convert';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_organizations_repository.dart';
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

  test('fetchOrganizationsPage sends pagination params and parses hasMore',
      () async {
    final adapter = _OrganizationsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminOrganizationsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final page = await repository.fetchOrganizationsPage(page: 1, pageSize: 2);

    expect(page.items, hasLength(2));
    expect(page.hasMore, isTrue);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.first.queryParameters['page'], 1);
    expect(adapter.requests.first.queryParameters['page_size'], 2);
  });

  test('load/reset/next follow paged stream contract for organizations',
      () async {
    final adapter = _OrganizationsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminOrganizationsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await verifyTenantAdminPagedStreamContract(
      scope: 'organizations',
      loadFirstPage: () => repository.loadOrganizations(pageSize: 2),
      loadNextPage: () => repository.loadNextOrganizationsPage(pageSize: 2),
      resetState: repository.resetOrganizationsState,
      readItems: () => repository.organizationsStreamValue.value,
      readHasMore: () => repository.hasMoreOrganizationsStreamValue.value,
      readError: () => repository.organizationsErrorStreamValue.value,
      expectedCountsPerStep: const [2, 3],
      loadNextCalls: 1,
    );
  });

  test('fetchOrganizationsPage tolerates missing optional slug/description',
      () async {
    final adapter = _OrganizationsRoutingAdapter(omitOptionalFields: true);
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminOrganizationsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final page = await repository.fetchOrganizationsPage(page: 1, pageSize: 2);

    expect(page.items, isNotEmpty);
    expect(page.items.first.slug, isNull);
    expect(page.items.first.description, isNull);
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

class _OrganizationsRoutingAdapter implements HttpClientAdapter {
  _OrganizationsRoutingAdapter({this.omitOptionalFields = false});

  final bool omitOptionalFields;
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
    final pageRaw = options.queryParameters['page'];
    final page = pageRaw is int ? pageRaw : int.tryParse('$pageRaw') ?? 1;

    if (options.path.endsWith('/v1/organizations')) {
      final payload = page == 1
          ? {
              'data': [
                _organizationJson(id: 'org-1', name: 'Org 1'),
                _organizationJson(id: 'org-2', name: 'Org 2'),
              ],
              'current_page': 1,
              'last_page': 2,
            }
          : {
              'data': [
                _organizationJson(id: 'org-3', name: 'Org 3'),
              ],
              'current_page': 2,
              'last_page': 2,
            };
      return _jsonResponse(payload);
    }

    return _jsonResponse({
      'data': const [],
      'current_page': page,
      'last_page': page,
    });
  }

  Map<String, dynamic> _organizationJson({
    required String id,
    required String name,
  }) {
    return {
      'id': id,
      'name': name,
      if (!omitOptionalFields) 'slug': name.toLowerCase().replaceAll(' ', '-'),
      if (!omitOptionalFields) 'description': 'Description for $name',
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
