import 'package:belluga_now/domain/repositories/landlord_tenants_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_selected_tenant_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto-selects the only tenant when available list has one item', () {
    final repository = TenantAdminSelectedTenantRepository();

    repository.setAvailableTenants(
      const [
        LandlordTenantOption(
          id: 'tenant-a',
          name: 'Tenant A',
          mainDomain: 'tenant-a.example.com',
        ),
      ],
    );

    expect(repository.availableTenants, hasLength(1));
    expect(repository.selectedTenantDomain, 'tenant-a.example.com');
    expect(repository.selectedTenant?.id, 'tenant-a');
  });

  test('selectTenantDomain preserves explicit origin and resolves tenant', () {
    final repository = TenantAdminSelectedTenantRepository();
    repository.setAvailableTenants(
      const [
        LandlordTenantOption(
          id: 'tenant-a',
          name: 'Tenant A',
          mainDomain: 'tenant-a.example.com',
        ),
        LandlordTenantOption(
          id: 'tenant-b',
          name: 'Tenant B',
          mainDomain: 'tenant-b.example.com',
        ),
      ],
    );

    repository.selectTenantDomain('https://tenant-b.example.com');

    expect(repository.selectedTenantDomain, 'https://tenant-b.example.com');
    expect(repository.selectedTenant?.id, 'tenant-b');
  });

  test(
      'selectTenantDomain preserves explicit scheme+port and computes matching admin base URL',
      () {
    final repository = TenantAdminSelectedTenantRepository();
    repository.setAvailableTenants(
      const [
        LandlordTenantOption(
          id: 'tenant-a',
          name: 'Tenant A',
          mainDomain: 'tenant-a.example.com',
        ),
      ],
    );

    repository.selectTenantDomain('http://tenant-a.example.com:8081');

    expect(
      repository.selectedTenantDomain,
      'http://tenant-a.example.com:8081',
    );
    expect(
      repository.selectedTenantAdminBaseUrl,
      'http://tenant-a.example.com:8081/admin/api',
    );
    expect(repository.selectedTenant?.id, 'tenant-a');
  });

  test(
      'single-tenant sync does not override explicit selected origin with host-only value',
      () {
    final repository = TenantAdminSelectedTenantRepository();
    repository.selectTenantDomain('http://tenant-a.example.com:8081');

    repository.setAvailableTenants(
      const [
        LandlordTenantOption(
          id: 'tenant-a',
          name: 'Tenant A',
          mainDomain: 'tenant-a.example.com',
        ),
      ],
    );

    expect(
      repository.selectedTenantDomain,
      'http://tenant-a.example.com:8081',
    );
    expect(repository.selectedTenant?.id, 'tenant-a');
  });

  test('clears selection when selected tenant disappears from available list',
      () {
    final repository = TenantAdminSelectedTenantRepository();
    repository.setAvailableTenants(
      const [
        LandlordTenantOption(
          id: 'tenant-a',
          name: 'Tenant A',
          mainDomain: 'tenant-a.example.com',
        ),
        LandlordTenantOption(
          id: 'tenant-b',
          name: 'Tenant B',
          mainDomain: 'tenant-b.example.com',
        ),
      ],
    );

    repository.selectTenantDomain('tenant-b.example.com');
    repository.setAvailableTenants(
      const [
        LandlordTenantOption(
          id: 'tenant-a',
          name: 'Tenant A',
          mainDomain: 'tenant-a.example.com',
        ),
      ],
    );

    expect(repository.selectedTenantDomain, 'tenant-a.example.com');
    expect(repository.selectedTenant?.id, 'tenant-a');
  });

  test('throws when base URL is requested without selected tenant', () {
    final repository = TenantAdminSelectedTenantRepository();

    expect(
      () => repository.selectedTenantAdminBaseUrl,
      throwsA(isA<StateError>()),
    );
  });

  test('clearSelectedTenantDomain clears both selected domain and option', () {
    final repository = TenantAdminSelectedTenantRepository();
    repository.selectTenant(
      const LandlordTenantOption(
        id: 'tenant-c',
        name: 'Tenant C',
        mainDomain: 'tenant-c.example.com',
      ),
    );

    repository.clearSelectedTenantDomain();

    expect(repository.selectedTenantDomain, isNull);
    expect(repository.selectedTenant, isNull);
  });
}
