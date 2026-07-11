import 'package:belluga_now/domain/app_data/value_object/app_data_required_text_value.dart';

class FirebaseSettings {
  FirebaseSettings({
    required this.apiKeyValue,
    this.appIdValue,
    this.androidAppIdValue,
    this.iosAppIdValue,
    required this.projectIdValue,
    required this.messagingSenderIdValue,
    required this.storageBucketValue,
  });

  final AppDataRequiredTextValue apiKeyValue;
  // TODO(v0.3.1+16-client-cutoff): remove legacy appId after no active
  // clients below 0.3.1+16 remain in use.
  final AppDataRequiredTextValue? appIdValue;
  final AppDataRequiredTextValue? androidAppIdValue;
  final AppDataRequiredTextValue? iosAppIdValue;
  final AppDataRequiredTextValue projectIdValue;
  final AppDataRequiredTextValue messagingSenderIdValue;
  final AppDataRequiredTextValue storageBucketValue;

  String get apiKey => apiKeyValue.value;
  String? get appId => appIdValue?.value;
  String? get androidAppId => androidAppIdValue?.value;
  String? get iosAppId => iosAppIdValue?.value;
  String get projectId => projectIdValue.value;
  String get messagingSenderId => messagingSenderIdValue.value;
  String get storageBucket => storageBucketValue.value;

  String? get androidBootstrapAppId {
    final resolvedAndroidAppId = androidAppId?.trim();
    if (resolvedAndroidAppId != null && resolvedAndroidAppId.isNotEmpty) {
      return resolvedAndroidAppId;
    }

    final resolvedLegacyAppId = appId?.trim();
    if (resolvedLegacyAppId == null ||
        resolvedLegacyAppId.isEmpty ||
        resolvedLegacyAppId.contains(':ios:')) {
      return null;
    }

    return resolvedLegacyAppId;
  }

  String? get iosBootstrapAppId {
    final resolvedIosAppId = iosAppId?.trim();
    if (resolvedIosAppId == null || resolvedIosAppId.isEmpty) {
      return null;
    }

    return resolvedIosAppId;
  }
}
