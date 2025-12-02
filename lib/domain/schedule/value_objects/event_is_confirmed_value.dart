import 'package:value_object_pattern/value_object.dart';

class EventIsConfirmedValue extends ValueObject<bool> {
  EventIsConfirmedValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  @override
  bool doParse(dynamic parseValue) {
    if (parseValue is bool) {
      return parseValue;
    }
    if (parseValue is String) {
      return parseValue.toLowerCase() == 'true';
    }
    return defaultValue;
  }
}
