class DomainValue {
  const DomainValue(this.value);

  final Uri value;
}

class AppData {
  const AppData({
    required this.href,
    required this.hostname,
    required this.schema,
    required this.mainDomainValue,
  });

  final String href;
  final String hostname;
  final String schema;
  final DomainValue mainDomainValue;
}

class TenantCanonicalDomainCase {
  String resolveFromCanonicalMainDomain(AppData appData) {
    return appData.mainDomainValue.value.resolve('/api').toString();
  }

  String invalidFromHref(AppData appData) {
    final origin = Uri.parse(
      // expect_lint: tenant_canonical_domain_required
      appData.href,
    );
    return origin.resolve('/api').toString();
  }

  String invalidHostname(AppData appData) {
    return 'https://'
        // expect_lint: tenant_canonical_domain_required
        '${appData.hostname}/api';
  }

  String invalidSchema(AppData appData) {
    return
        // expect_lint: tenant_canonical_domain_required
        '${appData.schema}://tenant.example/api';
  }
}
