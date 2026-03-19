import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class TenantAdminSettingsRepositoryContract {
  StreamValue<TenantAdminBrandingSettings?> get brandingSettingsStreamValue;

  void clearBrandingSettings();

  Future<TenantAdminMapUiSettings> fetchMapUiSettings();

  Future<TenantAdminMapUiSettings> updateMapUiSettings({
    required TenantAdminMapUiSettings settings,
  });

  Future<TenantAdminAppLinksSettings> fetchAppLinksSettings();

  Future<TenantAdminAppLinksSettings> updateAppLinksSettings({
    required TenantAdminAppLinksSettings settings,
  });

  Future<String> uploadMapFilterImage({
    required String key,
    required TenantAdminMediaUpload upload,
  });

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
