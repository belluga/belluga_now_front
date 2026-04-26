export 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_for_taxonomy_id.dart';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_for_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminTaxonomyTermsByTaxonomyId {
  const TenantAdminTaxonomyTermsByTaxonomyId.empty()
      : _entries = const <TenantAdminTaxonomyTermsForTaxonomyId>[];

  TenantAdminTaxonomyTermsByTaxonomyId({
    required List<TenantAdminTaxonomyTermsForTaxonomyId> entries,
  }) : _entries =
            List<TenantAdminTaxonomyTermsForTaxonomyId>.unmodifiable(entries);

  final List<TenantAdminTaxonomyTermsForTaxonomyId> _entries;

  List<TenantAdminTaxonomyTermDefinition> termsForId(
    TenantAdminRequiredTextValue taxonomyIdValue,
  ) {
    final taxonomyId = taxonomyIdValue.value;
    for (final entry in _entries) {
      if (entry.taxonomyId == taxonomyId) {
        return entry.terms;
      }
    }
    return const <TenantAdminTaxonomyTermDefinition>[];
  }
}
