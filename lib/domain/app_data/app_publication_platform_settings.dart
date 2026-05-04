import 'package:belluga_now/domain/app_data/value_object/app_publication_store_url_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class AppPublicationPlatformSettings {
  AppPublicationPlatformSettings({
    required this.enabledValue,
    required this.storeUrlValue,
  });

  AppPublicationPlatformSettings.inherit()
      : enabledValue = _enabledByDefaultValue(),
        storeUrlValue = AppPublicationStoreUrlValue();

  final DomainBooleanValue enabledValue;
  final AppPublicationStoreUrlValue storeUrlValue;

  bool get enabled => enabledValue.value;
  String? get storeUrl => storeUrlValue.nullableValue;
  bool get isPublished => enabled && storeUrl != null;
}

DomainBooleanValue _enabledByDefaultValue() {
  final value = DomainBooleanValue();
  value.parse('true');
  return value;
}
