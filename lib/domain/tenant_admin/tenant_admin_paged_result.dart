export 'value_objects/tenant_admin_paged_result_values.dart';

import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminPagedResult<T> {
  TenantAdminPagedResult({
    required this.items,
    required this.hasMoreValue,
  });

  final List<T> items;
  final TenantAdminFlagValue hasMoreValue;

  bool get hasMore => hasMoreValue.value;
}
