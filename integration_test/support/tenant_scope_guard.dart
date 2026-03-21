import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:flutter_test/flutter_test.dart';

class TenantScopeGuard {
  static const _expectedEnvironmentType =
      String.fromEnvironment('E2E_EXPECTED_ENV_TYPE', defaultValue: 'tenant');
  static const _expectedTenantMainDomain = String.fromEnvironment(
    'E2E_EXPECTED_TENANT_MAIN_DOMAIN',
    defaultValue: '',
  );
  static const _expectedTenantSubdomain = String.fromEnvironment(
    'E2E_EXPECTED_TENANT_SUBDOMAIN',
    defaultValue: '',
  );
  static const _requireTenantMainDomain = bool.fromEnvironment(
    'E2E_REQUIRE_TENANT_MAIN_DOMAIN',
    defaultValue: true,
  );

  static void assertTenantScope(
    AppData appData, {
    required String testName,
  }) {
    final actualType = appData.typeValue.value.name.toLowerCase();
    final expectedType = _expectedEnvironmentType.trim().toLowerCase();
    expect(
      actualType,
      expectedType,
      reason: '[$testName] Wrong environment scope. Expected "$expectedType" '
          'but received "$actualType".',
    );

    final tenantId = appData.tenantIdValue.value.toString().trim();
    expect(
      tenantId,
      isNotEmpty,
      reason:
          '[$testName] Missing tenant_id in app data. Test must run in tenant '
          'scope, not landlord scope.',
    );

    final actualMainDomain =
        _normalizeOrigin(appData.mainDomainValue.value.origin);
    final expectedMainDomain = _normalizeOrigin(_expectedTenantMainDomain);
    if (_requireTenantMainDomain && expectedMainDomain.isEmpty) {
      fail(
        '[$testName] Missing E2E_EXPECTED_TENANT_MAIN_DOMAIN. '
        'Provide the expected tenant main domain via --dart-define '
        '(example: https://guarappari.belluga.space).',
      );
    }

    if (expectedMainDomain.isNotEmpty) {
      expect(
        actualMainDomain,
        expectedMainDomain,
        reason:
            '[$testName] Wrong tenant main_domain. Expected "$expectedMainDomain" '
            'but received "$actualMainDomain".',
      );
    }

    final expectedSubdomain = _expectedTenantSubdomain.trim().toLowerCase();
    if (expectedSubdomain.isNotEmpty) {
      final actualHost = appData.mainDomainValue.value.host.toLowerCase();
      expect(
        actualHost.startsWith('$expectedSubdomain.'),
        isTrue,
        reason:
            '[$testName] Wrong tenant subdomain. Expected host to start with '
            '"$expectedSubdomain." but received "$actualHost".',
      );
    }

    final normalizedDomains = appData.domains
        .map((domain) => domain.value.host.toLowerCase())
        .toSet();
    final mainHost = appData.mainDomainValue.value.host.toLowerCase();
    expect(
      normalizedDomains.contains(mainHost),
      isTrue,
      reason: '[$testName] main_domain host must be listed in domains[] for '
          'tenant scope consistency.',
    );
  }

  static String _normalizeOrigin(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1).toLowerCase()
        : trimmed.toLowerCase();
  }
}
