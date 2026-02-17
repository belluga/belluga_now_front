import 'dart:convert';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_taxonomies_repository.dart';
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

  test('fetchTaxonomiesPage sends pagination params and parses hasMore',
      () async {
    final adapter = _TaxonomiesRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminTaxonomiesRepository(
      dio: dio,
      tenantScope: scope,
    );

    final result = await repository.fetchTaxonomiesPage(page: 1, pageSize: 2);

    expect(result.items, hasLength(2));
    expect(result.hasMore, isTrue);
    expect(adapter.requests, hasLength(1));
    expect(adapter.requests.first.queryParameters['page'], 1);
    expect(adapter.requests.first.queryParameters['page_size'], 2);
  });

  test('load/reset/next follow paged stream contract for taxonomies', () async {
    final adapter = _TaxonomiesRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminTaxonomiesRepository(
      dio: dio,
      tenantScope: scope,
    );

    await verifyTenantAdminPagedStreamContract(
      scope: 'taxonomies',
      loadFirstPage: () => repository.loadTaxonomies(pageSize: 2),
      loadNextPage: () => repository.loadNextTaxonomiesPage(pageSize: 2),
      resetState: repository.resetTaxonomiesState,
      readItems: () => repository.taxonomiesStreamValue.value,
      readHasMore: () => repository.hasMoreTaxonomiesStreamValue.value,
      readError: () => repository.taxonomiesErrorStreamValue.value,
      expectedCountsPerStep: const [2, 3],
      loadNextCalls: 1,
    );
  });

  test('load/reset/next follow paged stream contract for taxonomy terms',
      () async {
    final adapter = _TaxonomiesRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminTaxonomiesRepository(
      dio: dio,
      tenantScope: scope,
    );

    await verifyTenantAdminPagedStreamContract(
      scope: 'taxonomy terms',
      loadFirstPage: () =>
          repository.loadTerms(taxonomyId: 'tax-1', pageSize: 2),
      loadNextPage: () => repository.loadNextTermsPage(pageSize: 2),
      resetState: repository.resetTermsState,
      readItems: () => repository.termsStreamValue.value,
      readHasMore: () => repository.hasMoreTermsStreamValue.value,
      readError: () => repository.termsErrorStreamValue.value,
      expectedCountsPerStep: const [2, 3],
      loadNextCalls: 1,
    );
  });

  test('fetchTaxonomiesPage tolerates missing applies_to as legacy payload',
      () async {
    final adapter = _TaxonomiesRoutingAdapter(omitAppliesTo: true);
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminTaxonomiesRepository(
      dio: dio,
      tenantScope: scope,
    );

    final result = await repository.fetchTaxonomiesPage(page: 1, pageSize: 2);

    expect(result.items, isNotEmpty);
    expect(result.items.first.appliesTo, isEmpty);
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

class _TaxonomiesRoutingAdapter implements HttpClientAdapter {
  _TaxonomiesRoutingAdapter({this.omitAppliesTo = false});

  final bool omitAppliesTo;
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

    if (options.path.endsWith('/v1/taxonomies')) {
      final payload = page == 1
          ? {
              'data': [
                _taxonomyJson(id: 'tax-1', slug: 'genre', name: 'Genero'),
                _taxonomyJson(id: 'tax-2', slug: 'mood', name: 'Humor'),
              ],
              'current_page': 1,
              'last_page': 2,
            }
          : {
              'data': [
                _taxonomyJson(id: 'tax-3', slug: 'style', name: 'Estilo'),
              ],
              'current_page': 2,
              'last_page': 2,
            };
      return _jsonResponse(payload);
    }

    if (options.path.contains('/v1/taxonomies/tax-1/terms')) {
      final payload = page == 1
          ? {
              'data': [
                {
                  'id': 'term-1',
                  'taxonomy_id': 'tax-1',
                  'slug': 'samba',
                  'name': 'Samba',
                },
                {
                  'id': 'term-2',
                  'taxonomy_id': 'tax-1',
                  'slug': 'rock',
                  'name': 'Rock',
                },
              ],
              'current_page': 1,
              'last_page': 2,
            }
          : {
              'data': [
                {
                  'id': 'term-3',
                  'taxonomy_id': 'tax-1',
                  'slug': 'jazz',
                  'name': 'Jazz',
                },
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

  Map<String, dynamic> _taxonomyJson({
    required String id,
    required String slug,
    required String name,
  }) {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      if (!omitAppliesTo) 'applies_to': ['account_profile'],
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
