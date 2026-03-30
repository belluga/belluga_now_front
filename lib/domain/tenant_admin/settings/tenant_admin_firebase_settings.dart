import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_dynamic_map_value.dart';

class TenantAdminFirebaseSettings {
  TenantAdminFirebaseSettings({
    required TenantAdminRequiredTextValue apiKey,
    required TenantAdminRequiredTextValue appId,
    required TenantAdminRequiredTextValue projectId,
    required TenantAdminRequiredTextValue messagingSenderId,
    required TenantAdminRequiredTextValue storageBucket,
  })  : apiKeyValue = apiKey,
        appIdValue = appId,
        projectIdValue = projectId,
        messagingSenderIdValue = messagingSenderId,
        storageBucketValue = storageBucket;

  final TenantAdminRequiredTextValue apiKeyValue;
  final TenantAdminRequiredTextValue appIdValue;
  final TenantAdminRequiredTextValue projectIdValue;
  final TenantAdminRequiredTextValue messagingSenderIdValue;
  final TenantAdminRequiredTextValue storageBucketValue;

  String get apiKey => apiKeyValue.value;
  String get appId => appIdValue.value;
  String get projectId => projectIdValue.value;
  String get messagingSenderId => messagingSenderIdValue.value;
  String get storageBucket => storageBucketValue.value;

  TenantAdminDynamicMapValue toJson() {
    return TenantAdminDynamicMapValue({
      'apiKey': apiKey,
      'appId': appId,
      'projectId': projectId,
      'messagingSenderId': messagingSenderId,
      'storageBucket': storageBucket,
    });
  }
}
