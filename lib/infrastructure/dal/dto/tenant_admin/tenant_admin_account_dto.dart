class TenantAdminAccountDTO {
  const TenantAdminAccountDTO({
    required this.id,
    required this.name,
    required this.slug,
    required this.documentType,
    required this.documentNumber,
    this.organizationId,
    this.ownershipState,
  });

  final String id;
  final String name;
  final String slug;
  final String documentType;
  final String documentNumber;
  final String? organizationId;
  final String? ownershipState;

  factory TenantAdminAccountDTO.fromJson(Map<String, dynamic> json) {
    final document = json['document'];
    String? documentType;
    String? documentNumber;
    if (document is Map<String, dynamic>) {
      documentType = document['type']?.toString();
      documentNumber = document['number']?.toString();
    }
    return TenantAdminAccountDTO(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      documentType: documentType ?? '',
      documentNumber: documentNumber ?? '',
      organizationId: json['organization_id']?.toString(),
      ownershipState: json['ownership_state']?.toString(),
    );
  }
}
