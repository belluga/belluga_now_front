import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class ExperienceImageUrlValue extends URIValue {
  ExperienceImageUrlValue([String? raw])
      : super(defaultValue: null, isRequired: false) {
    final normalized = raw?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      parse(normalized);
    }
  }

  String? get nullableValue => value?.toString();
}
