import 'package:belluga_now/domain/repositories/value_objects/tenant_admin_taxonomies_repository_contract_values.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';

abstract class TenantAdminTaxonomiesBatchTermsRepositoryContract {
  Future<TenantAdminTaxonomyTermsByTaxonomyId> fetchTermsByTaxonomyIds({
    required List<TenantAdminTaxonomiesRepositoryContractTextValue> taxonomyIds,
  });
}
