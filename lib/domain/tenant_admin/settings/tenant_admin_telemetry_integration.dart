import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

typedef TenantAdminTelemetryIntegrationPrimString = String;
typedef TenantAdminTelemetryIntegrationPrimInt = int;
typedef TenantAdminTelemetryIntegrationPrimBool = bool;
typedef TenantAdminTelemetryIntegrationPrimDouble = double;
typedef TenantAdminTelemetryIntegrationPrimDateTime = DateTime;
typedef TenantAdminTelemetryIntegrationPrimDynamic = dynamic;

class TenantAdminTelemetryIntegration {
  TenantAdminTelemetryIntegration({
    required TenantAdminTelemetryIntegrationPrimString type,
    required TenantAdminTelemetryIntegrationPrimBool trackAll,
    required List<TenantAdminTelemetryIntegrationPrimString> events,
    TenantAdminTelemetryIntegrationPrimString? token,
    TenantAdminTelemetryIntegrationPrimString? url,
    Map<TenantAdminTelemetryIntegrationPrimString,
            TenantAdminTelemetryIntegrationPrimDynamic>?
        extra,
  })  : typeValue = _buildTypeValue(type),
        trackAllValue = _buildTrackAllValue(trackAll),
        eventValues = TenantAdminTrimmedStringListValue(events),
        tokenValue = _buildOptionalTextValue(token),
        urlValue = _buildOptionalUrlValue(url),
        extraValue = extra == null || extra.isEmpty
            ? null
            : TenantAdminDynamicMapValue(extra);

  final TenantAdminLowercaseTokenValue typeValue;
  final TenantAdminBooleanValue trackAllValue;
  final TenantAdminTrimmedStringListValue eventValues;
  final TenantAdminOptionalTextValue? tokenValue;
  final TenantAdminOptionalUrlValue? urlValue;
  final TenantAdminDynamicMapValue? extraValue;

  TenantAdminTelemetryIntegrationPrimString get type => typeValue.value;
  TenantAdminTelemetryIntegrationPrimBool get trackAll => trackAllValue.value;
  List<TenantAdminTelemetryIntegrationPrimString> get events =>
      eventValues.value;
  TenantAdminTelemetryIntegrationPrimString? get token =>
      tokenValue?.nullableValue;
  TenantAdminTelemetryIntegrationPrimString? get url => urlValue?.nullableValue;
  Map<TenantAdminTelemetryIntegrationPrimString,
          TenantAdminTelemetryIntegrationPrimDynamic>?
      get extra => extraValue?.value;

  Map<TenantAdminTelemetryIntegrationPrimString,
      TenantAdminTelemetryIntegrationPrimDynamic> toUpsertPayload() {
    return {
      'type': type,
      'track_all': trackAll,
      'events': events,
      if (token != null) 'token': token,
      if (url != null) 'url': url,
      if (extra != null) ...extra!,
    };
  }

  static TenantAdminLowercaseTokenValue _buildTypeValue(
      TenantAdminTelemetryIntegrationPrimString raw) {
    final value = TenantAdminLowercaseTokenValue()..parse(raw);
    return value;
  }

  static TenantAdminBooleanValue _buildTrackAllValue(
      TenantAdminTelemetryIntegrationPrimBool raw) {
    final value = TenantAdminBooleanValue()..parse(raw.toString());
    return value;
  }

  static TenantAdminOptionalTextValue? _buildOptionalTextValue(
      TenantAdminTelemetryIntegrationPrimString? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalTextValue()..parse(normalized);
    return value;
  }

  static TenantAdminOptionalUrlValue? _buildOptionalUrlValue(
      TenantAdminTelemetryIntegrationPrimString? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalUrlValue()..parse(normalized);
    return value;
  }
}
