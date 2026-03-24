import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_date_time_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_flag_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_date_time_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_double_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

TenantAdminRequiredTextValue tenantAdminRequiredText(Object? raw) {
  if (raw is TenantAdminRequiredTextValue) {
    return raw;
  }

  final value = TenantAdminRequiredTextValue();
  value.parse(raw?.toString());
  return value;
}

TenantAdminOptionalTextValue tenantAdminOptionalText(Object? raw) {
  if (raw is TenantAdminOptionalTextValue) {
    return raw;
  }

  final value = TenantAdminOptionalTextValue();
  value.parse(raw?.toString());
  return value;
}

TenantAdminOptionalUrlValue tenantAdminOptionalUrl(Object? raw) {
  if (raw is TenantAdminOptionalUrlValue) {
    return raw;
  }

  final value = TenantAdminOptionalUrlValue();
  value.parse(raw?.toString());
  return value;
}

TenantAdminTrimmedStringListValue tenantAdminTrimmedStringList(Object? raw) {
  if (raw is TenantAdminTrimmedStringListValue) {
    return raw;
  }

  if (raw is Iterable) {
    return TenantAdminTrimmedStringListValue(
      raw.map((item) => item?.toString() ?? ''),
    );
  }

  return TenantAdminTrimmedStringListValue();
}

TenantAdminFlagValue tenantAdminFlag(Object? raw, {bool fallback = false}) {
  if (raw is TenantAdminFlagValue) {
    return raw;
  }

  if (raw is bool) {
    return TenantAdminFlagValue(raw);
  }

  final normalized = raw?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return TenantAdminFlagValue(fallback);
  }

  if (normalized == 'true' || normalized == '1') {
    return const TenantAdminFlagValue(true);
  }
  if (normalized == 'false' || normalized == '0') {
    return const TenantAdminFlagValue(false);
  }

  throw FormatException('Invalid boolean value: $raw');
}

TenantAdminDateTimeValue tenantAdminDateTime(Object raw) {
  if (raw is TenantAdminDateTimeValue) {
    return raw;
  }

  if (raw is DateTime) {
    return TenantAdminDateTimeValue(raw);
  }

  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) {
    throw FormatException('Invalid date time value: $raw');
  }
  return TenantAdminDateTimeValue(parsed);
}

TenantAdminOptionalDateTimeValue tenantAdminOptionalDateTime(Object? raw) {
  if (raw is TenantAdminOptionalDateTimeValue) {
    return raw;
  }

  if (raw == null) {
    return const TenantAdminOptionalDateTimeValue(null);
  }

  if (raw is DateTime) {
    return TenantAdminOptionalDateTimeValue(raw);
  }

  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) {
    return const TenantAdminOptionalDateTimeValue(null);
  }
  return TenantAdminOptionalDateTimeValue(parsed);
}

TenantAdminOptionalDoubleValue tenantAdminOptionalDouble(Object? raw) {
  if (raw is TenantAdminOptionalDoubleValue) {
    return raw;
  }

  if (raw == null) {
    return const TenantAdminOptionalDoubleValue(null);
  }

  if (raw is num) {
    return TenantAdminOptionalDoubleValue(raw.toDouble());
  }

  final parsed = double.tryParse(raw.toString());
  if (parsed == null) {
    return const TenantAdminOptionalDoubleValue(null);
  }
  return TenantAdminOptionalDoubleValue(parsed);
}

TenantAdminDynamicMapValue tenantAdminDynamicMap(Object? raw) {
  if (raw is TenantAdminDynamicMapValue) {
    return raw;
  }

  if (raw is Map<String, dynamic>) {
    return TenantAdminDynamicMapValue(raw);
  }

  if (raw is Map) {
    return TenantAdminDynamicMapValue(Map<String, dynamic>.from(raw));
  }

  return TenantAdminDynamicMapValue();
}
