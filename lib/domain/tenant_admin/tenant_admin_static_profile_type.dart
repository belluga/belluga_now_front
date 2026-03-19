export 'tenant_admin_static_profile_type_capabilities.dart';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_static_profile_type_capabilities.dart';

class TenantAdminStaticProfileTypeDefinition {
  const TenantAdminStaticProfileTypeDefinition({
    required this.type,
    required this.label,
    required this.allowedTaxonomies,
    required this.capabilities,
  });

  final String type;
  final String label;
  final List<String> allowedTaxonomies;
  final TenantAdminStaticProfileTypeCapabilities capabilities;
}
