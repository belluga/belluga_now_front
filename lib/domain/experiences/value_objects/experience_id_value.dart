import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ExperienceIdValue extends GenericStringValue {
  ExperienceIdValue([String raw = ''])
      : super(defaultValue: '', isRequired: false) {
    parse(raw);
  }

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();
}
