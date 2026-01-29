import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';

abstract class TenantAdminOrganizationsRepositoryContract {
  Future<List<TenantAdminOrganization>> fetchOrganizations();
  Future<TenantAdminOrganization> fetchOrganization(String organizationId);
  Future<TenantAdminOrganization> createOrganization({
    required String name,
    String? description,
  });
  Future<TenantAdminOrganization> updateOrganization({
    required String organizationId,
    String? name,
    String? description,
  });
  Future<void> deleteOrganization(String organizationId);
  Future<TenantAdminOrganization> restoreOrganization(String organizationId);
  Future<void> forceDeleteOrganization(String organizationId);
}
