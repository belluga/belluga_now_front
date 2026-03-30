import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class UserIdentityStateValue extends GenericStringValue {
  UserIdentityStateValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory UserIdentityStateValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = UserIdentityStateValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    value.parse(raw?.toString());
    return value;
  }

  bool get isAnonymous => value == 'anonymous';

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim().toLowerCase();
  }
}
