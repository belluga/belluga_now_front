import 'package:value_object_pattern/value_object.dart';

class TeacherIsHighlight extends ValueObject<bool> {
  TeacherIsHighlight({super.defaultValue = false, super.isRequired = true});

  @override
  bool doParse(String? parseValue) {
    if (parseValue == null || parseValue == "0") {
      return false;
    }

    if (parseValue.toLowerCase() == "false") {
      return false;
    }

    return true;
  }
}
