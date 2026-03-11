import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_taxonomy_term_option.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_type_option.dart';

class TenantAdminMapFilterRuleCatalog {
  const TenantAdminMapFilterRuleCatalog({
    required this.typesBySource,
    required this.taxonomyTermsBySource,
  });

  const TenantAdminMapFilterRuleCatalog.empty()
      : typesBySource = const <TenantAdminMapFilterSource,
            List<TenantAdminMapFilterTypeOption>>{},
        taxonomyTermsBySource = const <TenantAdminMapFilterSource,
            List<TenantAdminMapFilterTaxonomyTermOption>>{};

  final Map<TenantAdminMapFilterSource, List<TenantAdminMapFilterTypeOption>>
      typesBySource;
  final Map<TenantAdminMapFilterSource,
      List<TenantAdminMapFilterTaxonomyTermOption>> taxonomyTermsBySource;

  bool get isEmpty => typesBySource.isEmpty && taxonomyTermsBySource.isEmpty;

  List<TenantAdminMapFilterTypeOption> typesForSource(
    TenantAdminMapFilterSource source,
  ) {
    return typesBySource[source] ?? const <TenantAdminMapFilterTypeOption>[];
  }

  List<TenantAdminMapFilterTaxonomyTermOption> taxonomyForSource(
    TenantAdminMapFilterSource source,
  ) {
    return taxonomyTermsBySource[source] ??
        const <TenantAdminMapFilterTaxonomyTermOption>[];
  }
}
