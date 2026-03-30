import 'package:value_object_pattern/value_object.dart';

class HomeAgendaBooleanValue extends ValueObject<bool> {
  HomeAgendaBooleanValue({
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
