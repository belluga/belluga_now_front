import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/app_data_backend/environment_origin_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aligns main_domain scheme with bootstrap origin for same host', () {
    final payload = <String, dynamic>{
      'main_domain': 'https://192.168.15.4.nip.io:8081',
      'domains': <String>[],
    };

    final normalized = normalizeEnvironmentOrigins(
      payload,
      bootstrapBaseUrl: 'http://192.168.15.4.nip.io:8081',
    );

    expect(
      normalized['main_domain'],
      'http://192.168.15.4.nip.io:8081',
    );
  });

  test('aligns tenant subdomain scheme and inherits bootstrap port', () {
    final payload = <String, dynamic>{
      'main_domain': 'https://guarappari.192.168.15.4.nip.io',
      'domains': <String>['guarappari.192.168.15.4.nip.io'],
    };

    final normalized = normalizeEnvironmentOrigins(
      payload,
      bootstrapBaseUrl: 'http://192.168.15.4.nip.io:8081',
    );

    expect(
      normalized['main_domain'],
      'http://guarappari.192.168.15.4.nip.io:8081',
    );
    expect(
      normalized['domains'],
      <String>['http://guarappari.192.168.15.4.nip.io:8081'],
    );
  });

  test('does not rewrite unrelated domains', () {
    final payload = <String, dynamic>{
      'main_domain': 'https://tenant.other.test',
      'domains': <String>[
        'https://tenant.other.test',
        'https://another.domain.test',
      ],
    };

    final normalized = normalizeEnvironmentOrigins(
      payload,
      bootstrapBaseUrl: 'http://192.168.15.4.nip.io:8081',
    );

    expect(normalized['main_domain'], 'https://tenant.other.test');
    expect(
      normalized['domains'],
      <String>[
        'https://tenant.other.test',
        'https://another.domain.test',
      ],
    );
  });

  test('returns a copy unchanged for invalid bootstrap origin', () {
    final payload = <String, dynamic>{
      'main_domain': 'https://tenant.example.test',
      'domains': <String>['https://tenant.example.test'],
    };

    final normalized = normalizeEnvironmentOrigins(
      payload,
      bootstrapBaseUrl: 'tenant.example.test',
    );

    expect(normalized, payload);
    expect(identical(normalized, payload), isFalse);
  });
}
