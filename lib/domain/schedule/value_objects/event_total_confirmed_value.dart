import 'package:value_object_pattern/value_object.dart';

class EventTotalConfirmedValue extends ValueObject<int> {
  EventTotalConfirmedValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  @override
  int doParse(dynamic parseValue) {
    if (parseValue is int) {
      return parseValue;
    }
    if (parseValue is String) {
      return int.tryParse(parseValue) ?? defaultValue;
    }
    return defaultValue;
  }
}
