import 'package:value_object_pattern/value_object.dart';

class EventOccurrenceFlagValue extends ValueObject<bool> {
  EventOccurrenceFlagValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  @override
  bool doParse(dynamic parseValue) {
    if (parseValue is bool) {
      return parseValue;
    }
    if (parseValue is num) {
      return parseValue != 0;
    }
    if (parseValue is String) {
      final normalized = parseValue.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return defaultValue;
  }
}
