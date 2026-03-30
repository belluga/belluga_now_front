import 'package:value_object_pattern/value_object.dart';

class TenantAdminFlagValue extends ValueObject<bool> {
  TenantAdminFlagValue([bool raw = false])
      : super(defaultValue: false, isRequired: true) {
    parse(raw.toString());
  }

  @override
  bool doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    if (normalized == 'true') {
      return true;
    }
    if (normalized == 'false') {
      return false;
    }
    return defaultValue;
  }
}
