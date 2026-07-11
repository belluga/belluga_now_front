import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';

class TenantAdminFirebaseSettings {
  TenantAdminFirebaseSettings({
    required TenantAdminRequiredTextValue apiKey,
    required TenantAdminRequiredTextValue androidAppId,
    TenantAdminRequiredTextValue? iosAppId,
    required TenantAdminRequiredTextValue projectId,
    required TenantAdminRequiredTextValue messagingSenderId,
    required TenantAdminRequiredTextValue storageBucket,
  }) : apiKeyValue = apiKey,
       androidAppIdValue = androidAppId,
       iosAppIdValue = iosAppId,
       projectIdValue = projectId,
       messagingSenderIdValue = messagingSenderId,
       storageBucketValue = storageBucket;

  final TenantAdminRequiredTextValue apiKeyValue;
  final TenantAdminRequiredTextValue androidAppIdValue;
  final TenantAdminRequiredTextValue? iosAppIdValue;
  final TenantAdminRequiredTextValue projectIdValue;
  final TenantAdminRequiredTextValue messagingSenderIdValue;
  final TenantAdminRequiredTextValue storageBucketValue;

  String get apiKey => apiKeyValue.value;
  String get androidAppId => androidAppIdValue.value;
  String? get iosAppId => iosAppIdValue?.value;
  String get projectId => projectIdValue.value;
  String get messagingSenderId => messagingSenderIdValue.value;
  String get storageBucket => storageBucketValue.value;

  TenantAdminDynamicMapValue toJson() {
    final raw = <String, dynamic>{
      'apiKey': apiKey,
      'androidAppId': androidAppId,
      'projectId': projectId,
      'messagingSenderId': messagingSenderId,
      'storageBucket': storageBucket,
    };
    final resolvedIosAppId = iosAppId;
    if (resolvedIosAppId != null && resolvedIosAppId.trim().isNotEmpty) {
      raw['iosAppId'] = resolvedIosAppId;
    }
    return TenantAdminDynamicMapValue(raw);
  }
}
