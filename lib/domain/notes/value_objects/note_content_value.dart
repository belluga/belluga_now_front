import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class NoteContentValue extends GenericStringValue {
  NoteContentValue({
    required super.defaultValue,
    super.isRequired = true,
    super.maxLenght = 400,
    super.minLenght = 3,
  });
}
