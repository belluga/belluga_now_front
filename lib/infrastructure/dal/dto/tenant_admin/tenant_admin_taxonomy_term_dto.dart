import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

class TenantAdminTaxonomyTermDTO {
  const TenantAdminTaxonomyTermDTO({
    required this.type,
    required this.value,
  });

  final String type;
  final String value;

  factory TenantAdminTaxonomyTermDTO.fromJson(Map<String, dynamic> json) {
    return TenantAdminTaxonomyTermDTO(
      type: json['type']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  TenantAdminTaxonomyTerm toDomain() {
    return TenantAdminTaxonomyTerm(
      type: type,
      value: value,
    );
  }
}
