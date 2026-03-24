import 'package:belluga_now/domain/app_data/value_object/app_data_required_text_value.dart';

class FirebaseSettings {
  FirebaseSettings({
    required this.apiKeyValue,
    required this.appIdValue,
    required this.projectIdValue,
    required this.messagingSenderIdValue,
    required this.storageBucketValue,
  });

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
}
