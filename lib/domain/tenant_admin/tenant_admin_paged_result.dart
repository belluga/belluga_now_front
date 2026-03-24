import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';

class TenantAdminPagedResult<T> {
  TenantAdminPagedResult({
    required this.items,
    required Object hasMore,
  }) : hasMoreValue = tenantAdminFlag(hasMore);

  final List<T> items;
  final TenantAdminFlagValue hasMoreValue;

  bool get hasMore => hasMoreValue.value;
}
