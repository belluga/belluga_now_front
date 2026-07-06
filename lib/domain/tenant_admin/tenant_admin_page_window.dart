import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_count_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';

class TenantAdminPageWindow {
  TenantAdminPageWindow({
    required this.currentPageValue,
    required this.pageSizeValue,
    required this.hasMoreValue,
  });

  final TenantAdminCountValue currentPageValue;
  final TenantAdminCountValue pageSizeValue;
  final TenantAdminFlagValue hasMoreValue;

  int get currentPage => currentPageValue.value;
  int get pageSize => pageSizeValue.value;
  bool get hasMore => hasMoreValue.value;
}
