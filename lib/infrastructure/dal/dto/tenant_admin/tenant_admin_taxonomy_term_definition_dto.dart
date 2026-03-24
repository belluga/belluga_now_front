import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';

class TenantAdminTaxonomyTermDefinitionDTO {
  const TenantAdminTaxonomyTermDefinitionDTO({
    required this.id,
    required this.taxonomyId,
    required this.slug,
    required this.name,
  });

  final String id;
  final String taxonomyId;
  final String slug;
  final String name;

  factory TenantAdminTaxonomyTermDefinitionDTO.fromJson(
    Map<String, dynamic> json,
  ) {
    return TenantAdminTaxonomyTermDefinitionDTO(
      id: json['id']?.toString() ?? '',
      taxonomyId: json['taxonomy_id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  TenantAdminTaxonomyTermDefinition toDomain() {
    return TenantAdminTaxonomyTermDefinition(
      id: id,
      taxonomyId: taxonomyId,
      slug: slug,
      name: name,
    );
  }
}
