import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_app_links_settings.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_android_app_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_bundle_identifier_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_ios_team_id_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_sha256_fingerprint_list_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';
import 'package:belluga_now/testing/tenant_admin_app_links_settings_builder.dart';

void main() {
  test('builds app links settings with validated identifiers and fingerprints',
      () {
    final settings = buildTenantAdminAppLinksSettings(
      rawAppLinks: const {
        'android': {
          'sha256_cert_fingerprints': [
            '3e:72:4c:54:e9:53:26:7d:e6:e1:9b:f8:dc:53:30:2a:08:01:8e:36:40:4d:0c:ca:98:3b:46:84:53:e7:a9:a9',
          ],
        },
        'ios': {
          'team_id': 'abcde12345',
          'paths': ['/invite*', '/convites*'],
        },
      },
      androidAppIdentifier: 'com.guarappari.app',
      androidSha256CertFingerprints: const [
        '3e:72:4c:54:e9:53:26:7d:e6:e1:9b:f8:dc:53:30:2a:08:01:8e:36:40:4d:0c:ca:98:3b:46:84:53:e7:a9:a9',
      ],
      iosTeamId: 'abcde12345',
      iosBundleId: 'com.guarappari.app',
      iosPaths: const ['/convites*', '/invite*'],
    );

    expect(settings.androidAppIdentifier, 'com.guarappari.app');
    expect(
      settings.androidSha256CertFingerprints,
      equals(
        const [
          '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:4D:0C:CA:98:3B:46:84:53:E7:A9:A9',
        ],
      ),
    );
    expect(settings.iosTeamId, 'ABCDE12345');
    expect(settings.iosBundleId, 'com.guarappari.app');
    expect(settings.iosPaths, equals(const ['/invite*', '/convites*']));
  });

  test('rejects invalid android app identifier', () {
    expect(
      () => buildTenantAdminAppLinksSettings(
        rawAppLinks: const {},
        androidAppIdentifier: 'invalid package',
        androidSha256CertFingerprints: const [
          '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:4D:0C:CA:98:3B:46:84:53:E7:A9:A9',
        ],
        iosTeamId: null,
        iosBundleId: null,
        iosPaths: TenantAdminAppLinksSettings.canonicalIosPaths,
      ),
      throwsA(isA<InvalidValueException>()),
    );
  });

  test('rejects invalid iOS team id', () {
    expect(
      () => buildTenantAdminAppLinksSettings(
        rawAppLinks: const {},
        androidAppIdentifier: 'com.guarappari.app',
        androidSha256CertFingerprints: const [
          '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:4D:0C:CA:98:3B:46:84:53:E7:A9:A9',
        ],
        iosTeamId: 'invalid',
        iosBundleId: 'com.guarappari.app',
        iosPaths: TenantAdminAppLinksSettings.canonicalIosPaths,
      ),
      throwsA(isA<InvalidValueException>()),
    );
  });

  test('applyValues writes credential-only payload and preserves identifiers',
      () {
    final current =
        TenantAdminAppLinksSettings.empty().withAppDomainIdentifiers(
      androidAppIdentifier: _androidAppIdentifier('com.guarappari.app'),
      iosBundleId: _iosBundleId('com.guarappari.app'),
    );

    final updated = current.applyValues(
      androidAppIdentifier: _androidAppIdentifier('com.guarappari.app'),
      androidSha256CertFingerprints: TenantAdminSha256FingerprintListValue([
        '3E:72:4C:54:E9:53:26:7D:E6:E1:9B:F8:DC:53:30:2A:08:01:8E:36:40:4D:0C:CA:98:3B:46:84:53:E7:A9:A9',
      ]),
      iosTeamId: _iosTeamId('ABCDE12345'),
      iosBundleId: _iosBundleId('com.guarappari.app'),
      iosPaths: TenantAdminTrimmedStringListValue(const ['/invite*', '/convites*']),
    );

    expect(updated.androidAppIdentifier, 'com.guarappari.app');
    expect(updated.iosBundleId, 'com.guarappari.app');
    expect(updated.rawAppLinks['android'], isA<Map<String, dynamic>>());
    expect(
      (updated.rawAppLinks['android'] as Map<String, dynamic>)
          .containsKey('package_name'),
      isFalse,
    );
    expect(updated.rawAppLinks['ios'], isA<Map<String, dynamic>>());
    expect(
      (updated.rawAppLinks['ios'] as Map<String, dynamic>)
          .containsKey('bundle_id'),
      isFalse,
    );
    expect(updated.iosPaths, equals(const ['/invite*', '/convites*']));
  });
}

TenantAdminAndroidAppIdentifierValue _androidAppIdentifier(String raw) {
  final value = TenantAdminAndroidAppIdentifierValue();
  value.parse(raw);
  return value;
}

TenantAdminIosBundleIdentifierValue _iosBundleId(String raw) {
  final value = TenantAdminIosBundleIdentifierValue();
  value.parse(raw);
  return value;
}

TenantAdminIosTeamIdValue _iosTeamId(String raw) {
  final value = TenantAdminIosTeamIdValue();
  value.parse(raw);
  return value;
}
