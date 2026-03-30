import 'package:value_object_pattern/value_object.dart';

class AccountProfileAcceptedInvitesValue extends ValueObject<int> {
  AccountProfileAcceptedInvitesValue([int raw = 0])
    : super(defaultValue: raw, isRequired: false) {
    set(raw);
  }

  @override
  int doParse(dynamic parseValue) {
    if (parseValue is int) {
      return parseValue;
    }
    if (parseValue is num) {
      return parseValue.toInt();
    }
    return int.tryParse(parseValue?.toString() ?? '') ?? defaultValue;
  }
}
