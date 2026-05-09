import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_positive_int_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';

class TenantAdminPushSettings {
  TenantAdminPushSettings({
    required this.maxTtlDaysValue,
    required this.maxPerMinuteValue,
    required this.maxPerHourValue,
    this.enabledValue,
  });

  final TenantAdminPositiveIntValue maxTtlDaysValue;
  final TenantAdminPositiveIntValue maxPerMinuteValue;
  final TenantAdminPositiveIntValue maxPerHourValue;
  final TenantAdminBooleanValue? enabledValue;

  int get maxTtlDays => maxTtlDaysValue.value;
  int get maxPerMinute => maxPerMinuteValue.value;
  int get maxPerHour => maxPerHourValue.value;
  bool? get enabled => enabledValue?.value;

  TenantAdminDynamicMapValue toJson() {
    return TenantAdminDynamicMapValue({
      'max_ttl_days': maxTtlDays,
      'throttles': {
        'max_per_minute': maxPerMinute,
        'max_per_hour': maxPerHour,
      },
    });
  }
}
