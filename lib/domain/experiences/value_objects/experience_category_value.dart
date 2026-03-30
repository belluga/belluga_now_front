import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ExperienceCategoryValue extends GenericStringValue {
  ExperienceCategoryValue([String raw = ''])
      : super(defaultValue: '', isRequired: false) {
    parse(raw);
  }

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim();
}
