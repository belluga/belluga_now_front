import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_positive_int_value.dart';

typedef TenantAdminPushSettingsPrimString = String;
typedef TenantAdminPushSettingsPrimInt = int;
typedef TenantAdminPushSettingsPrimBool = bool;
typedef TenantAdminPushSettingsPrimDouble = double;
typedef TenantAdminPushSettingsPrimDateTime = DateTime;
typedef TenantAdminPushSettingsPrimDynamic = dynamic;

class TenantAdminPushSettings {
  TenantAdminPushSettings({
    required TenantAdminPushSettingsPrimInt maxTtlDays,
    required TenantAdminPushSettingsPrimInt maxPerMinute,
    required TenantAdminPushSettingsPrimInt maxPerHour,
  })  : maxTtlDaysValue = _buildPositiveIntValue(maxTtlDays),
        maxPerMinuteValue = _buildPositiveIntValue(maxPerMinute),
        maxPerHourValue = _buildPositiveIntValue(maxPerHour);

  final TenantAdminPositiveIntValue maxTtlDaysValue;
  final TenantAdminPositiveIntValue maxPerMinuteValue;
  final TenantAdminPositiveIntValue maxPerHourValue;

  TenantAdminPushSettingsPrimInt get maxTtlDays => maxTtlDaysValue.value;
  TenantAdminPushSettingsPrimInt get maxPerMinute => maxPerMinuteValue.value;
  TenantAdminPushSettingsPrimInt get maxPerHour => maxPerHourValue.value;

  Map<TenantAdminPushSettingsPrimString, TenantAdminPushSettingsPrimDynamic>
      toJson() {
    return {
      'max_ttl_days': maxTtlDays,
      'throttles': {
        'max_per_minute': maxPerMinute,
        'max_per_hour': maxPerHour,
      },
    };
  }

  static TenantAdminPositiveIntValue _buildPositiveIntValue(
      TenantAdminPushSettingsPrimInt raw) {
    final value = TenantAdminPositiveIntValue()..parse(raw.toString());
    return value;
  }
}
