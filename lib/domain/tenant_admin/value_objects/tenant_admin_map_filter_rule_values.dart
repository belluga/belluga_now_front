import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_source.dart';
import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_map_filter_type_option.dart';

export 'tenant_admin_map_filter_taxonomy_options_by_source_value.dart';

class TenantAdminMapFilterTypeOptionsBySourceValue {
  const TenantAdminMapFilterTypeOptionsBySourceValue.empty()
      : _value = const <TenantAdminMapFilterSource,
            List<TenantAdminMapFilterTypeOption>>{};

  TenantAdminMapFilterTypeOptionsBySourceValue([
    Map<TenantAdminMapFilterSource, List<TenantAdminMapFilterTypeOption>>?
        rawValue,
  ]) : _value = rawValue == null
            ? const <TenantAdminMapFilterSource,
                List<TenantAdminMapFilterTypeOption>>{}
            : Map<TenantAdminMapFilterSource,
                List<TenantAdminMapFilterTypeOption>>.unmodifiable(
                rawValue.map(
                  (source, options) => MapEntry(
                    source,
                    List<TenantAdminMapFilterTypeOption>.unmodifiable(options),
                  ),
                ),
              );

  final Map<TenantAdminMapFilterSource, List<TenantAdminMapFilterTypeOption>>
      _value;

  bool get isEmpty => _value.isEmpty;

  List<TenantAdminMapFilterTypeOption> optionsFor(
    TenantAdminMapFilterSource source,
  ) {
    return _value[source] ?? const <TenantAdminMapFilterTypeOption>[];
  }
}
