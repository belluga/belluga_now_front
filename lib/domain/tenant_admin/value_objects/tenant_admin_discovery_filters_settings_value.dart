import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminDiscoveryFiltersSettingsValue extends ValueObject<String> {
  TenantAdminDiscoveryFiltersSettingsValue([
    TenantAdminDynamicMapValue? rawValue,
  ])  : rawDiscoveryFilters = rawValue ?? TenantAdminDynamicMapValue(),
        super(defaultValue: '', isRequired: false) {
    parse('discovery_filters');
  }

  final TenantAdminDynamicMapValue rawDiscoveryFilters;

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();
}
