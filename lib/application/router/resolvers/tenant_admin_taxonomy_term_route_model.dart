import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';

class TenantAdminTaxonomyTermRouteModel {
  const TenantAdminTaxonomyTermRouteModel({
    required this.taxonomy,
    required this.term,
  });

  final TenantAdminTaxonomyDefinition taxonomy;
  final TenantAdminTaxonomyTermDefinition term;
}
