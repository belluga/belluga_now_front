export 'tenant_admin_page_window.dart';
export 'value_objects/tenant_admin_paged_result_values.dart';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_page_window.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminPagedResult<T> {
  TenantAdminPagedResult({
    required this.items,
    required this.hasMoreValue,
    this.pagination,
  });

  final List<T> items;
  final TenantAdminFlagValue hasMoreValue;
  final TenantAdminPageWindow? pagination;

  bool get hasMore => pagination?.hasMore ?? hasMoreValue.value;
}
