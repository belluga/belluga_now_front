import 'package:value_object_pattern/value_object.dart';

class AccountProfileIsVerifiedValue extends ValueObject<bool> {
  AccountProfileIsVerifiedValue([bool raw = false])
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
