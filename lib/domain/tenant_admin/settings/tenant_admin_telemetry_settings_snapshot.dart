import 'package:belluga_now/domain/tenant_admin/settings/tenant_admin_telemetry_integration.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_trimmed_string_list_value.dart';

class TenantAdminTelemetrySettingsSnapshot {
  TenantAdminTelemetrySettingsSnapshot({
    required this.integrations,
    required this.availableEventValues,
  });

  TenantAdminTelemetrySettingsSnapshot.empty()
      : integrations = const [],
        availableEventValues = TenantAdminTrimmedStringListValue();

  final List<TenantAdminTelemetryIntegration> integrations;
  final TenantAdminTrimmedStringListValue availableEventValues;

  List<String> get availableEvents => availableEventValues.value;
}
