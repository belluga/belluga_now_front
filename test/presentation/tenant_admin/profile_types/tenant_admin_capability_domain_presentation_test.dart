import 'package:belluga_now/presentation/tenant_admin/profile_types/tenant_admin_capability_domain_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps every canonical domain to its Portuguese presentation label', () {
    expect(tenantAdminCapabilityDomainLabel('visibility'), 'Visibilidade');
    expect(
      tenantAdminCapabilityDomainLabel('relationships'),
      'Relacionamentos',
    );
    expect(
      tenantAdminCapabilityDomainLabel('profile_content'),
      'Perfil e conteúdo',
    );
    expect(tenantAdminCapabilityDomainLabel('events'), 'Eventos');
    expect(tenantAdminCapabilityDomainLabel('location'), 'Localização');
  });

  test('renders an unknown backend domain unchanged', () {
    expect(
      tenantAdminCapabilityDomainLabel('future_backend_domain'),
      'future_backend_domain',
    );
  });

  test('humanizes any backend capability key without a local catalog', () {
    expect(
      tenantAdminCapabilityLabel('future_backend_capability'),
      'Future backend capability',
    );
    expect(tenantAdminCapabilityLabel(''), '');
  });
}
