import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term_definition.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms_by_taxonomy_id.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminTaxonomyTermsBySlug {
  const TenantAdminTaxonomyTermsBySlug._(this._termsBySlug);

  factory TenantAdminTaxonomyTermsBySlug.fromTaxonomies({
    required List<TenantAdminTaxonomyDefinition> taxonomies,
    required TenantAdminTaxonomyTermsByTaxonomyId termsByTaxonomyId,
  }) {
    return TenantAdminTaxonomyTermsBySlug._({
      for (final taxonomy in taxonomies)
        taxonomy.slug: termsByTaxonomyId.termsForId(
          tenantAdminRequiredText(taxonomy.id),
        ),
    });
  }

  factory TenantAdminTaxonomyTermsBySlug.fromMap(
    Map<String, List<TenantAdminTaxonomyTermDefinition>> termsBySlug,
  ) {
    return TenantAdminTaxonomyTermsBySlug._({
      for (final entry in termsBySlug.entries)
        entry.key: List<TenantAdminTaxonomyTermDefinition>.unmodifiable(
          entry.value,
        ),
    });
  }

  final Map<String, List<TenantAdminTaxonomyTermDefinition>> _termsBySlug;

  List<TenantAdminTaxonomyTermDefinition> termsForSlug(String slug) {
    return _termsBySlug[slug] ?? const <TenantAdminTaxonomyTermDefinition>[];
  }
}
