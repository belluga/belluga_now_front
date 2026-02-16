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
      const TenantAdminOrganization(id: 'org-1', name: 'Tenant A'),
    ]);
    final tenantScope = _FakeTenantScope('tenant-a.test');
    final controller = TenantAdminOrganizationsController(
      organizationsRepository: repository,
      tenantScope: tenantScope,
    );

    await controller.loadOrganizations();
    expect(controller.organizationsStreamValue.value?.first.name, 'Tenant A');

    repository.organizations = [
      const TenantAdminOrganization(id: 'org-2', name: 'Tenant B'),
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
    required String name,
    String? description,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteOrganization(String organizationId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<TenantAdminOrganization>> fetchOrganizations() async =>
      organizations;

  @override
  Future<TenantAdminPagedResult<TenantAdminOrganization>>
      fetchOrganizationsPage({
    required int page,
    required int pageSize,
  }) async {
    final all = await fetchOrganizations();
    final start = (page - 1) * pageSize;
    if (page <= 0 || pageSize <= 0 || start >= all.length) {
      return const TenantAdminPagedResult<TenantAdminOrganization>(
        items: <TenantAdminOrganization>[],
        hasMore: false,
      );
    }
    final end = start + pageSize < all.length ? start + pageSize : all.length;
    return TenantAdminPagedResult<TenantAdminOrganization>(
      items: all.sublist(start, end),
      hasMore: end < all.length,
    );
  }

  @override
  Future<TenantAdminOrganization> fetchOrganization(String organizationId) {
    throw UnimplementedError();
  }

  @override
  Future<void> forceDeleteOrganization(String organizationId) async {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminOrganization> restoreOrganization(String organizationId) {
    throw UnimplementedError();
  }

  @override
  Future<TenantAdminOrganization> updateOrganization({
    required String organizationId,
    String? name,
    String? slug,
    String? description,
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
  void selectTenantDomain(String tenantDomain) {
    _selectedTenantDomainStreamValue.addValue(tenantDomain.trim());
  }
}
