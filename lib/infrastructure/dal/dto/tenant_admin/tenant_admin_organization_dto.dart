import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';

class TenantAdminOrganizationDTO {
  const TenantAdminOrganizationDTO({
    required this.id,
    required this.name,
    this.slug,
    this.description,
  });

  final String id;
  final String name;
  final String? slug;
  final String? description;

  factory TenantAdminOrganizationDTO.fromJson(Map<String, dynamic> json) {
    return TenantAdminOrganizationDTO(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
    );
  }

  TenantAdminOrganization toDomain() {
    return tenantAdminOrganizationFromRaw(
      id: id,
      name: name,
      slug: slug,
      description: description,
    );
  }
}
