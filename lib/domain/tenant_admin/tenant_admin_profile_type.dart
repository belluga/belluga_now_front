export 'tenant_admin_profile_type_capabilities.dart';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart';

class TenantAdminProfileTypeDefinition {
  const TenantAdminProfileTypeDefinition({
    required this.type,
    required this.label,
    required this.allowedTaxonomies,
    required this.capabilities,
  });

  final String type;
  final String label;
  final List<String> allowedTaxonomies;
  final TenantAdminProfileTypeCapabilities capabilities;
}
