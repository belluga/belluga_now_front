import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_boolean_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_optional_url_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminTelemetryIntegration {
  TenantAdminTelemetryIntegration({
    required String type,
    required bool trackAll,
    required List<String> events,
    String? token,
    String? url,
    Map<String, dynamic>? extra,
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

  static TenantAdminLowercaseTokenValue _buildTypeValue(String raw) {
    final value = TenantAdminLowercaseTokenValue()..parse(raw);
    return value;
  }

  static TenantAdminBooleanValue _buildTrackAllValue(bool raw) {
    final value = TenantAdminBooleanValue()..parse(raw.toString());
    return value;
  }

  static TenantAdminOptionalTextValue? _buildOptionalTextValue(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalTextValue()..parse(normalized);
    return value;
  }

  static TenantAdminOptionalUrlValue? _buildOptionalUrlValue(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = TenantAdminOptionalUrlValue()..parse(normalized);
    return value;
  }
}
