import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps explicit scheme when selected domain already has origin', () {
    final baseUrl = resolveTenantAdminBaseUrl('https://tenant.test:8081');
    expect(baseUrl, 'https://tenant.test:8081/admin/api');
  });

  test('uses landlord scheme when selected domain has no scheme', () {
    final baseUrl = resolveTenantAdminBaseUrl(
      'guarappari.192.168.15.5.nip.io:8081',
      landlordOriginOverride: 'http://192.168.15.5.nip.io:8081',
    );
    expect(baseUrl, 'http://guarappari.192.168.15.5.nip.io:8081/admin/api');
  });

  test('uses landlord port when selected domain omits port', () {
    final baseUrl = resolveTenantAdminBaseUrl(
      'guarappari.192.168.15.5.nip.io',
      landlordOriginOverride: 'http://192.168.15.5.nip.io:8081',
    );
    expect(baseUrl, 'http://guarappari.192.168.15.5.nip.io:8081/admin/api');
  });

  test('throws when tenant domain has no scheme and landlord is missing', () {
    expect(
      () => resolveTenantAdminBaseUrl(
        'tenant.127.0.0.1.nip.io:8081',
        landlordOriginOverride: '',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('throws when landlord origin is invalid', () {
    expect(
      () => resolveTenantAdminBaseUrl(
        'guarappari.192.168.15.5.nip.io',
        landlordOriginOverride: '192.168.15.5.nip.io:8081',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('throws when selected domain is empty', () {
    expect(
      () => resolveTenantAdminBaseUrl('   '),
      throwsA(isA<StateError>()),
    );
  });
}
