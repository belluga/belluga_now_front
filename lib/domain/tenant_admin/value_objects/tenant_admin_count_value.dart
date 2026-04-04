import 'package:value_object_pattern/value_object.dart';

class TenantAdminCountValue extends ValueObject<int> {
  TenantAdminCountValue([int raw = 0])
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
      final parsed = int.tryParse(parseValue.trim()) ?? defaultValue;
      return parsed < 0 ? 0 : parsed;
    }
    return defaultValue;
  }
}
