import 'package:belluga_now/domain/app_data/value_object/app_data_required_text_value.dart';

class FirebaseSettings {
  FirebaseSettings({
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

  final AppDataRequiredTextValue apiKeyValue;
  final AppDataRequiredTextValue appIdValue;
  final AppDataRequiredTextValue projectIdValue;
  final AppDataRequiredTextValue messagingSenderIdValue;
  final AppDataRequiredTextValue storageBucketValue;

  String get apiKey => apiKeyValue.value;
  String get appId => appIdValue.value;
  String get projectId => projectIdValue.value;
  String get messagingSenderId => messagingSenderIdValue.value;
  String get storageBucket => storageBucketValue.value;

  static FirebaseSettings? tryFromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final apiKey = map['apiKey'] as String?;
    final appId = map['appId'] as String?;
    final projectId = map['projectId'] as String?;
    final messagingSenderId = map['messagingSenderId'] as String?;
    final storageBucket = map['storageBucket'] as String?;

    if ([
      apiKey,
      appId,
      projectId,
      messagingSenderId,
      storageBucket,
    ].any((value) => value == null || value.trim().isEmpty)) {
      return null;
    }

    return FirebaseSettings(
      apiKey: apiKey!,
      appId: appId!,
      projectId: projectId!,
      messagingSenderId: messagingSenderId!,
      storageBucket: storageBucket!,
    );
  }

  static AppDataRequiredTextValue _buildRequiredTextValue(String raw) {
    final value = AppDataRequiredTextValue()..parse(raw);
    return value;
  }
}
