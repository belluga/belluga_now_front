import 'package:value_object_pattern/value_object.dart';

class NoteTitleValue extends ValueObject<String?> {
  NoteTitleValue({super.defaultValue, super.isRequired = false});

  @override
  String? doParse(String? parseValue) {
    if (parseValue == null || parseValue.isEmpty) {
      return null;
    }
    return parseValue.trim();
  }

  @override
  String get valueFormated {
    if (super.valueFormated.isEmpty) {
      return '';
    }
    return super.valueFormated.split(' ').map((word) {
      if (word.isEmpty) {
        return '';
      }
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
