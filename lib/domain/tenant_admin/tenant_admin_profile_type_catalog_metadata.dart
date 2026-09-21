import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart';

class TenantAdminProfileTypeCatalogMetadata {
  const TenantAdminProfileTypeCatalogMetadata({
    required this.capabilityDefinitions,
    required this.capabilityCreationConfiguration,
  });

  const TenantAdminProfileTypeCatalogMetadata.empty()
    : capabilityDefinitions = const [],
      capabilityCreationConfiguration =
          const TenantAdminProfileTypeCapabilities.empty();

  final List<TenantAdminProfileTypeCapabilityDefinition> capabilityDefinitions;
  final TenantAdminProfileTypeCapabilities capabilityCreationConfiguration;
}
