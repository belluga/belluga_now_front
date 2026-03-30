import 'package:value_object_pattern/value_object.dart';

class DomainBooleanValue extends ValueObject<bool> {
  DomainBooleanValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  @override
  bool doParse(dynamic parseValue) {
    if (parseValue is bool) {
      return parseValue;
    }
    if (parseValue is String) {
      final normalized = parseValue.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return defaultValue;
  }
}
