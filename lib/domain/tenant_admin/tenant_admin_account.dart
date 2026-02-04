import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_document.dart';

class TenantAdminAccount {
  const TenantAdminAccount({
    required this.id,
    required this.name,
    required this.slug,
    required this.document,
    required this.ownershipState,
    this.organizationId,
  });

  final String id;
  final String name;
  final String slug;
  final TenantAdminDocument document;
  final TenantAdminOwnershipState ownershipState;
  final String? organizationId;
}
