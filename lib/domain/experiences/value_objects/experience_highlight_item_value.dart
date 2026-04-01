import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class ExperienceHighlightItemValue extends GenericStringValue {
  ExperienceHighlightItemValue({
    String raw = '',
    super.isRequired = false,
  }) : super(defaultValue: '', minLenght: 1) {
    parse(raw);
  }
}
