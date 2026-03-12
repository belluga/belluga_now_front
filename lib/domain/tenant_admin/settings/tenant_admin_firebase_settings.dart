import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';

class TenantAdminFirebaseSettings {
  TenantAdminFirebaseSettings({
    required String apiKey,
    required String appId,
    required String projectId,
    required String messagingSenderId,
    required String storageBucket,
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

  String get apiKey => apiKeyValue.value;
  String get appId => appIdValue.value;
  String get projectId => projectIdValue.value;
  String get messagingSenderId => messagingSenderIdValue.value;
  String get storageBucket => storageBucketValue.value;

  Map<String, dynamic> toJson() {
    return {
      'apiKey': apiKey,
      'appId': appId,
      'projectId': projectId,
      'messagingSenderId': messagingSenderId,
      'storageBucket': storageBucket,
    };
  }

  static TenantAdminRequiredTextValue _buildRequiredTextValue(String raw) {
    final value = TenantAdminRequiredTextValue()..parse(raw);
    return value;
  }
}
