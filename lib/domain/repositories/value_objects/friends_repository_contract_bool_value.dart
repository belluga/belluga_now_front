import 'package:value_object_pattern/value_object.dart';

class FriendsRepositoryContractBoolValue extends ValueObject<bool> {
  FriendsRepositoryContractBoolValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  factory FriendsRepositoryContractBoolValue.fromRaw(
    Object? raw, {
    bool defaultValue = false,
    bool isRequired = true,
  }) {
    final value = FriendsRepositoryContractBoolValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    value.parse(raw?.toString());
    return value;
  }

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
