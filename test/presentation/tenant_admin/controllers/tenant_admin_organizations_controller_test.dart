import 'package:belluga_now/domain/repositories/tenant_admin_organizations_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/controllers/tenant_admin_organizations_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('reloads organizations when tenant scope changes', () async {
    final repository = _FakeOrganizationsRepository([
      tenantAdminOrganizationFromRaw(id: 'org-1', name: 'Tenant A'),
    ]);
    final tenantScope = _FakeTenantScope('tenant-a.test');
    final controller = TenantAdminOrganizationsController(
      organizationsRepository: repository,
      tenantScope: tenantScope,
    );

    await controller.loadOrganizations();
    expect(controller.organizationsStreamValue.value?.first.name, 'Tenant A');

    repository.organizations = [
      tenantAdminOrganizationFromRaw(id: 'org-2', name: 'Tenant B'),
    ];
    tenantScope.selectTenantDomain('tenant-b.test');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(controller.organizationsStreamValue.value?.first.name, 'Tenant B');
  });
}

class _FakeOrganizationsRepository
    with TenantAdminOrganizationsPaginationMixin
    implements TenantAdminOrganizationsRepositoryContract {
  _FakeOrganizationsRepository(this.organizations);

  List<TenantAdminOrganization> organizations;

  @override
  Future<TenantAdminOrganization> createOrganization({
    required TenantAdminOrganizationsRepositoryContractPrimString name,
    TenantAdminOrganizationsRepositoryContractPrimString? description,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteOrganization(
    TenantAdminOrganizationsRepositoryContractPrimString organizationId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminOrganization>> fetchOrganizations() async =>
      organizations;

  @override
  Future<TenantAdminPagedResult<TenantAdminOrganization>>
      fetchOrganizationsPage({
    required TenantAdminOrganizationsRepositoryContractPrimInt page,
    required TenantAdminOrganizationsRepositoryContractPrimInt pageSize,
  }) async {
    final all = await fetchOrganizations();
    final start = (page.value - 1) * pageSize.value;
    if (page.value <= 0 || pageSize.value <= 0 || start >= all.length) {
      return tenantAdminPagedResultFromRaw(
        items: <TenantAdminOrganization>[],
        hasMore: false,
      );
    }
    final end = start + pageSize.value < all.length
        ? start + pageSize.value
        : all.length;
    return tenantAdminPagedResultFromRaw(
      items: all.sublist(start, end),
      hasMore: end < all.length,
    );
  }

  @override
  Future<TenantAdminOrganization> fetchOrganization(
    TenantAdminOrganizationsRepositoryContractPrimString organizationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteOrganization(
    TenantAdminOrganizationsRepositoryContractPrimString organizationId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminOrganization> restoreOrganization(
    TenantAdminOrganizationsRepositoryContractPrimString organizationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminOrganization> updateOrganization({
    required TenantAdminOrganizationsRepositoryContractPrimString
        organizationId,
    TenantAdminOrganizationsRepositoryContractPrimString? name,
    TenantAdminOrganizationsRepositoryContractPrimString? slug,
    TenantAdminOrganizationsRepositoryContractPrimString? description,
  }) {
    throw UnimplementedError();
  }
}

class _FakeTenantScope implements TenantAdminTenantScopeContract {
  _FakeTenantScope(String initialDomain)
      : _selectedTenantDomainStreamValue =
            StreamValue<String?>(defaultValue: initialDomain);

  final StreamValue<String?> _selectedTenantDomainStreamValue;

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl =>
      'https://${selectedTenantDomain ?? ''}/admin/api';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue((tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim());
  }
}
