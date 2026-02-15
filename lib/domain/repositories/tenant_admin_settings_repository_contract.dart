import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';

abstract class TenantAdminSettingsRepositoryContract {
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
}
