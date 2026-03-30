import 'dart:convert';

import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/landlord_tenants_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetchTenants returns one option per tenant with preferred main domain',
      () async {
    final adapter = _TenantListAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = LandlordTenantsRepository(
      dio: dio,
      landlordAuthRepository: _StubAuthRepo(),
      landlordOriginOverride: 'https://landlord.example.com',
    );

    final tenants = await repository.fetchTenants();

    expect(
      tenants
          .map((entry) =>
              (id: entry.id, name: entry.name, domain: entry.mainDomain))
          .toList(growable: false),
      equals([
        (id: 'alpha', name: 'Alpha Tenant', domain: 'alpha.example.com'),
        (id: 'beta', name: 'Beta Tenant', domain: 'beta.example.com'),
        (
          id: 'epsilon',
          name: 'Epsilon Tenant',
          domain: 'epsilon.landlord.example.com',
        ),
        (
          id: 'gamma',
          name: 'Gamma Tenant',
          domain: 'gamma.landlord.example.com'
        ),
      ]),
    );
    expect(
      adapter.lastRequest?.path,
      contains('https://landlord.example.com/admin/api/v1/tenants'),
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
  Future<void> loginWithEmailPassword(
      LandlordAuthRepositoryContractPrimString email,
      LandlordAuthRepositoryContractPrimString password) async {}

  @override
  Future<void> logout() async {}
}

class _TenantListAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    lastRequest = options;
    final page =
        int.tryParse(options.queryParameters['page']?.toString() ?? '1') ?? 1;

    if (page == 1) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': [
            {
              'slug': 'alpha',
              'name': 'Alpha Tenant',
              'subdomain': 'alpha',
              'domains': [
                {
                  'path': 'https://alpha.example.com',
                  'is_main': true,
                },
              ],
              'app_domains': ['com.alpha.app'],
            },
            {
              'slug': 'beta',
              'name': 'Beta Tenant',
              'subdomain': 'beta',
              'domains': [
                {'path': 'https://beta.example.com'},
              ],
              'app_domains': [
                {'path': 'com.beta.app'},
              ],
            },
            {
              'slug': 'gamma',
              'name': 'Gamma Tenant',
              'subdomain': 'gamma',
              'app_domains': [],
            },
            {
              'slug': 'delta',
              'name': 'Delta Tenant',
              'app_domains': ['delta.app.example.com'],
            },
            {
              'slug': 'epsilon',
              'name': 'Epsilon Tenant',
              'subdomain': 'epsilon',
              'app_domains': [
                'com.epsilon.app',
                'epsilon.secondary.app',
              ],
            },
          ],
          'last_page': 1,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({
        'data': [],
        'last_page': 1,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
