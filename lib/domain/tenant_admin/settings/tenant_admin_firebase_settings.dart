import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

typedef TenantAdminFirebaseSettingsPrimString = String;
typedef TenantAdminFirebaseSettingsPrimInt = int;
typedef TenantAdminFirebaseSettingsPrimBool = bool;
typedef TenantAdminFirebaseSettingsPrimDouble = double;
typedef TenantAdminFirebaseSettingsPrimDateTime = DateTime;
typedef TenantAdminFirebaseSettingsPrimDynamic = dynamic;

class TenantAdminFirebaseSettings {
  TenantAdminFirebaseSettings({
    required TenantAdminFirebaseSettingsPrimString apiKey,
    required TenantAdminFirebaseSettingsPrimString appId,
    required TenantAdminFirebaseSettingsPrimString projectId,
    required TenantAdminFirebaseSettingsPrimString messagingSenderId,
    required TenantAdminFirebaseSettingsPrimString storageBucket,
  })  : apiKeyValue = _buildRequiredTextValue(apiKey),
        appIdValue = _buildRequiredTextValue(appId),
        projectIdValue = _buildRequiredTextValue(projectId),
        messagingSenderIdValue = _buildRequiredTextValue(messagingSenderId),
        storageBucketValue = _buildRequiredTextValue(storageBucket);

  final TenantAdminRequiredTextValue apiKeyValue;
  final TenantAdminRequiredTextValue appIdValue;
  final TenantAdminRequiredTextValue projectIdValue;
  final TenantAdminRequiredTextValue messagingSenderIdValue;
  final TenantAdminRequiredTextValue storageBucketValue;

  TenantAdminFirebaseSettingsPrimString get apiKey => apiKeyValue.value;
  TenantAdminFirebaseSettingsPrimString get appId => appIdValue.value;
  TenantAdminFirebaseSettingsPrimString get projectId => projectIdValue.value;
  TenantAdminFirebaseSettingsPrimString get messagingSenderId =>
      messagingSenderIdValue.value;
  TenantAdminFirebaseSettingsPrimString get storageBucket =>
      storageBucketValue.value;

  Map<TenantAdminFirebaseSettingsPrimString,
      TenantAdminFirebaseSettingsPrimDynamic> toJson() {
    return {
      'apiKey': apiKey,
      'appId': appId,
      'projectId': projectId,
      'messagingSenderId': messagingSenderId,
      'storageBucket': storageBucket,
    };
  }

  static TenantAdminRequiredTextValue _buildRequiredTextValue(
      TenantAdminFirebaseSettingsPrimString raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }
}
