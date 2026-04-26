import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

class TenantAdminTaxonomyTermDTO {
  const TenantAdminTaxonomyTermDTO({
    required this.type,
    required this.value,
    this.name,
    this.taxonomyName,
    this.label,
  });

  final String type;
  final String value;
  final String? name;
  final String? taxonomyName;
  final String? label;

  factory TenantAdminTaxonomyTermDTO.fromJson(Map<String, dynamic> json) {
    return TenantAdminTaxonomyTermDTO(
      type: json['type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      name: json['name']?.toString(),
      taxonomyName: json['taxonomy_name']?.toString(),
      label: json['label']?.toString(),
    );
  }

  TenantAdminTaxonomyTerm toDomain() {
    return tenantAdminTaxonomyTermFromRaw(
      type: type,
      value: value,
      name: name,
      taxonomyName: taxonomyName,
      label: label,
    );
  }
}
