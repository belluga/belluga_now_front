import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_nested_profile_group_values.dart';

class TenantAdminGroupOrderEntry {
  const TenantAdminGroupOrderEntry({
    required this.idValue,
    required this.orderValue,
  });

  final TenantAdminNestedProfileGroupTextValue idValue;
  final TenantAdminNestedProfileGroupOrderValue orderValue;

  String get id => idValue.value;
  int get order => orderValue.value;
}
