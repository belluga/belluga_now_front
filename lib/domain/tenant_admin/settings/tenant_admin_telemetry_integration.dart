import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminTelemetryIntegration {
  TenantAdminTelemetryIntegration({
    required TenantAdminLowercaseTokenValue type,
    required TenantAdminBooleanValue trackAll,
    required TenantAdminTrimmedStringListValue events,
    TenantAdminOptionalTextValue? token,
    TenantAdminOptionalUrlValue? url,
    TenantAdminDynamicMapValue? extra,
  })  : typeValue = type,
        trackAllValue = trackAll,
        eventValues = events,
        tokenValue = token,
        urlValue = url,
        extraValue = extra;

  final TenantAdminLowercaseTokenValue typeValue;
  final TenantAdminBooleanValue trackAllValue;
  final TenantAdminTrimmedStringListValue eventValues;
  final TenantAdminOptionalTextValue? tokenValue;
  final TenantAdminOptionalUrlValue? urlValue;
  final TenantAdminDynamicMapValue? extraValue;

  String get type => typeValue.value;
  bool get trackAll => trackAllValue.value;
  List<String> get events => eventValues.value;
  String? get token => tokenValue?.nullableValue;
  String? get url => urlValue?.nullableValue;
  Map<String, dynamic>? get extra => extraValue?.value;

  Map<String, dynamic> toUpsertPayload() {
    return {
      'type': type,
      'track_all': trackAll,
      'events': events,
      if (token != null) 'token': token,
      if (url != null) 'url': url,
      if (extra != null) ...extra!,
    };
  }
}
