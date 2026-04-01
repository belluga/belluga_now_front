import 'package:value_object_pattern/value_object.dart';

class ExperienceOptionalTextValue extends ValueObject<String> {
  ExperienceOptionalTextValue([String? raw])
      : super(defaultValue: '', isRequired: false) {
    final normalized = raw?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      parse(normalized);
    }
  }

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();

  String? get nullableValue {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }
}
