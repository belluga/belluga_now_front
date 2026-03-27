import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_positive_int_value.dart';

class TenantAdminPushSettings {
  TenantAdminPushSettings({
    required this.maxTtlDaysValue,
    required this.maxPerMinuteValue,
    required this.maxPerHourValue,
  });

  final TenantAdminPositiveIntValue maxTtlDaysValue;
  final TenantAdminPositiveIntValue maxPerMinuteValue;
  final TenantAdminPositiveIntValue maxPerHourValue;

  int get maxTtlDays => maxTtlDaysValue.value;
  int get maxPerMinute => maxPerMinuteValue.value;
  int get maxPerHour => maxPerHourValue.value;

  Map<String, dynamic> toJson() {
    return {
      'max_ttl_days': maxTtlDays,
      'throttles': {
        'max_per_minute': maxPerMinute,
        'max_per_hour': maxPerHour,
      },
    };
  }
}
