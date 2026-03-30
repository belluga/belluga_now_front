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
    required List<TenantAdminLowercaseTokenValue> eventValues,
    TenantAdminOptionalTextValue? token,
    TenantAdminOptionalUrlValue? url,
    this.rawExtraValue,
  })  : typeValue = type,
        trackAllValue = trackAll,
        eventValues = _eventListValue(eventValues),
        tokenValue = token,
        urlValue = url;

  final TenantAdminLowercaseTokenValue typeValue;
  final TenantAdminBooleanValue trackAllValue;
  final TenantAdminTrimmedStringListValue eventValues;
  final TenantAdminOptionalTextValue? tokenValue;
  final TenantAdminOptionalUrlValue? urlValue;
  final TenantAdminDynamicMapValue? rawExtraValue;

  String get type => typeValue.value;
  bool get trackAll => trackAllValue.value;
  TenantAdminTrimmedStringListValue get events => eventValues;
  String? get token => tokenValue?.nullableValue;
  String? get url => urlValue?.nullableValue;
  TenantAdminDynamicMapValue? get rawExtra => rawExtraValue;

  TenantAdminDynamicMapValue toUpsertPayload() {
    return TenantAdminDynamicMapValue({
      'type': type,
      'track_all': trackAll,
      'events': events,
      if (token != null) 'token': token,
      if (url != null) 'url': url,
      if (rawExtra != null) ...rawExtra!.value,
    });
  }

  static TenantAdminTrimmedStringListValue _eventListValue(
    List<TenantAdminLowercaseTokenValue> rawValues,
  ) {
    return TenantAdminTrimmedStringListValue(
      rawValues.map((entry) => entry.value),
    );
  }
}
