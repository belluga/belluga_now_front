import 'package:value_object_pattern/value_object.dart';

class EventProfileGroupOrderValue extends ValueObject<int> {
  EventProfileGroupOrderValue([int raw = 0])
      : super(defaultValue: 0, isRequired: true) {
    parse(raw.toString());
  }

  @override
  int doParse(dynamic parseValue) {
    if (parseValue is int) {
      return parseValue < 0 ? 0 : parseValue;
    }
    if (parseValue is num) {
      final value = parseValue.toInt();
      return value < 0 ? 0 : value;
    }
    if (parseValue is String) {
      final value = int.tryParse(parseValue.trim()) ?? defaultValue;
      return value < 0 ? 0 : value;
    }
    return defaultValue;
  }
}
