import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_taxonomy_term_option.dart';

class TenantAdminMapFilterTaxonomyOptionsBySourceValue {
  const TenantAdminMapFilterTaxonomyOptionsBySourceValue.empty()
      : _value = const <TenantAdminMapFilterSource,
            List<TenantAdminMapFilterTaxonomyTermOption>>{};

  TenantAdminMapFilterTaxonomyOptionsBySourceValue([
    Map<TenantAdminMapFilterSource,
            List<TenantAdminMapFilterTaxonomyTermOption>>?
        rawValue,
  ]) : _value = rawValue == null
            ? const <TenantAdminMapFilterSource,
                List<TenantAdminMapFilterTaxonomyTermOption>>{}
            : Map<TenantAdminMapFilterSource,
                List<TenantAdminMapFilterTaxonomyTermOption>>.unmodifiable(
                rawValue.map(
                  (source, options) => MapEntry(
                    source,
                    List<TenantAdminMapFilterTaxonomyTermOption>.unmodifiable(
                      options,
                    ),
                  ),
                ),
              );

  final Map<TenantAdminMapFilterSource,
      List<TenantAdminMapFilterTaxonomyTermOption>> _value;

  bool get isEmpty => _value.isEmpty;

  List<TenantAdminMapFilterTaxonomyTermOption> optionsFor(
    TenantAdminMapFilterSource source,
  ) {
    return _value[source] ?? const <TenantAdminMapFilterTaxonomyTermOption>[];
  }
}
