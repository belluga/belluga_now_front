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
}
