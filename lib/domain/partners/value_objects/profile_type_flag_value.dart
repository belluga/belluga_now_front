import 'package:value_object_pattern/value_object.dart';

class ProfileTypeFlagValue extends ValueObject<bool> {
  ProfileTypeFlagValue([bool raw = false])
    : super(defaultValue: raw, isRequired: false) {
    set(raw);
  }

  @override
  bool doParse(dynamic parseValue) {
    if (parseValue is bool) {
      return parseValue;
    }
    final normalized = parseValue?.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
