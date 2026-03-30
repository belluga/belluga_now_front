import 'package:value_object_pattern/value_object.dart';

class EngagementCountValue extends ValueObject<int> {
  EngagementCountValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  @override
  int doParse(dynamic parseValue) {
    if (parseValue is int) {
      return parseValue;
    }
    if (parseValue is num) {
      return parseValue.toInt();
    }
    if (parseValue is String) {
      return int.tryParse(parseValue.trim()) ?? defaultValue;
    }
    return defaultValue;
  }
}
