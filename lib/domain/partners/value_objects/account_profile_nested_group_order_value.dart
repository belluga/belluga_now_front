import 'package:value_object_pattern/value_object.dart';

class AccountProfileNestedGroupOrderValue extends ValueObject<int> {
  AccountProfileNestedGroupOrderValue([int raw = 0])
      : super(defaultValue: 0, isRequired: false) {
    parse(raw.toString());
  }

  @override
  int doParse(dynamic parseValue) {
    if (parseValue is num) {
      return parseValue.toInt();
    }
    return int.tryParse(parseValue?.toString() ?? '') ?? 0;
  }
}
