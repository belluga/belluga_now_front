import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_capabilities.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type_catalog_metadata.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_profile_type_dto.dart';

class TenantAdminProfileTypeCatalogDTO {
  const TenantAdminProfileTypeCatalogDTO({
    required this.items,
    required this.capabilityDefinitions,
    required this.capabilityCreationConfiguration,
  });

  final List<TenantAdminProfileTypeDTO> items;
  final List<TenantAdminProfileTypeCapabilityDefinition> capabilityDefinitions;
  final TenantAdminProfileTypeCapabilities capabilityCreationConfiguration;

  TenantAdminProfileTypeCatalogMetadata get metadata =>
      TenantAdminProfileTypeCatalogMetadata(
        capabilityDefinitions: capabilityDefinitions,
        capabilityCreationConfiguration: capabilityCreationConfiguration,
      );
}
