import 'dart:math' as math;

import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_paged_result.dart';

abstract class TenantAdminOrganizationsRepositoryContract {
  Future<List<TenantAdminOrganization>> fetchOrganizations();
  Future<TenantAdminPagedResult<TenantAdminOrganization>>
      fetchOrganizationsPage({
    required int page,
    required int pageSize,
  }) async {
    final organizations = await fetchOrganizations();
    if (page <= 0 || pageSize <= 0) {
      return const TenantAdminPagedResult<TenantAdminOrganization>(
        items: <TenantAdminOrganization>[],
        hasMore: false,
      );
    }
    final startIndex = (page - 1) * pageSize;
    if (startIndex >= organizations.length) {
      return const TenantAdminPagedResult<TenantAdminOrganization>(
        items: <TenantAdminOrganization>[],
        hasMore: false,
      );
    }
    final endIndex = math.min(startIndex + pageSize, organizations.length);
    return TenantAdminPagedResult<TenantAdminOrganization>(
      items: organizations.sublist(startIndex, endIndex),
      hasMore: endIndex < organizations.length,
    );
  }

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
