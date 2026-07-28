import 'package:value_object_pattern/value_object.dart';

class EventProfileGroupMemberCountValue extends ValueObject<int> {
  EventProfileGroupMemberCountValue([Object? raw])
    : super(defaultValue: 0, isRequired: false) {
    parse(raw?.toString());
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
    final value = int.tryParse(parseValue?.toString().trim() ?? '') ?? 0;
    return value < 0 ? 0 : value;
  }
}
