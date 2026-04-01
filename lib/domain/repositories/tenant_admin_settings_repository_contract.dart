import 'package:belluga_now/domain/tenant_admin/tenant_admin_settings.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_lowercase_token_value.dart';
import 'package:stream_value/core/stream_value.dart';

typedef TenantAdminSettingsRepositoryContractPrimString = String;
typedef TenantAdminSettingsRepositoryContractPrimInt = int;
typedef TenantAdminSettingsRepositoryContractPrimBool = bool;
typedef TenantAdminSettingsRepositoryContractPrimDouble = double;
typedef TenantAdminSettingsRepositoryContractPrimDateTime = DateTime;
typedef TenantAdminSettingsRepositoryContractPrimDynamic = dynamic;

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

  Future<TenantAdminSettingsRepositoryContractPrimString> uploadMapFilterImage({
    required TenantAdminLowercaseTokenValue key,
    required TenantAdminMediaUpload upload,
  });

  Future<TenantAdminFirebaseSettings?> fetchFirebaseSettings();

  Future<TenantAdminFirebaseSettings> updateFirebaseSettings({
    required TenantAdminFirebaseSettings settings,
  });

  Future<TenantAdminResendEmailSettings> fetchResendEmailSettings();

  Future<TenantAdminResendEmailSettings> updateResendEmailSettings({
    required TenantAdminResendEmailSettings settings,
  });

  Future<TenantAdminPushSettings> updatePushSettings({
    required TenantAdminPushSettings settings,
  });

  Future<TenantAdminTelemetrySettingsSnapshot> fetchTelemetrySettings();

  Future<TenantAdminTelemetrySettingsSnapshot> upsertTelemetryIntegration({
    required TenantAdminTelemetryIntegration integration,
  });

  Future<TenantAdminTelemetrySettingsSnapshot> deleteTelemetryIntegration({
    required TenantAdminLowercaseTokenValue type,
  });

  Future<TenantAdminBrandingSettings> fetchBrandingSettings();

  Future<TenantAdminBrandingSettings> updateBranding({
    required TenantAdminBrandingUpdateInput input,
  });
}
