import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminSettingsRepositoryContract {
  StreamValue<TenantAdminBrandingSettings?> get brandingSettingsStreamValue;

  void clearBrandingSettings();

  Future<TenantAdminFirebaseSettings?> fetchFirebaseSettings();

  Future<TenantAdminFirebaseSettings> updateFirebaseSettings({
    required TenantAdminFirebaseSettings settings,
  });

  Future<TenantAdminPushSettings> updatePushSettings({
    required TenantAdminPushSettings settings,
  });

  Future<TenantAdminTelemetrySettingsSnapshot> fetchTelemetrySettings();

  Future<TenantAdminTelemetrySettingsSnapshot> upsertTelemetryIntegration({
    required TenantAdminTelemetryIntegration integration,
  });

  Future<TenantAdminTelemetrySettingsSnapshot> deleteTelemetryIntegration({
    required String type,
  });

  Future<TenantAdminBrandingSettings> fetchBrandingSettings();

  Future<TenantAdminBrandingSettings> updateBranding({
    required TenantAdminBrandingUpdateInput input,
  });
}
