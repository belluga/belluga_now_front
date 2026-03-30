import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_taxonomy_term_option.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_type_option.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_map_filter_rule_values.dart';

class TenantAdminMapFilterRuleCatalog {
  const TenantAdminMapFilterRuleCatalog({
    required this.typesBySource,
    required this.taxonomyTermsBySource,
  });

  const TenantAdminMapFilterRuleCatalog.empty()
      : typesBySource =
            const TenantAdminMapFilterTypeOptionsBySourceValue.empty(),
        taxonomyTermsBySource =
            const TenantAdminMapFilterTaxonomyOptionsBySourceValue.empty();

  final TenantAdminMapFilterTypeOptionsBySourceValue typesBySource;
  final TenantAdminMapFilterTaxonomyOptionsBySourceValue taxonomyTermsBySource;

  bool get isEmpty => typesBySource.isEmpty && taxonomyTermsBySource.isEmpty;

  List<TenantAdminMapFilterTypeOption> typesForSource(
    TenantAdminMapFilterSource source,
  ) {
    return typesBySource.optionsFor(source);
  }

  List<TenantAdminMapFilterTaxonomyTermOption> taxonomyForSource(
    TenantAdminMapFilterSource source,
  ) {
    return taxonomyTermsBySource.optionsFor(source);
  }
}
