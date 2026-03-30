import 'package:value_object_pattern/value_object.dart';

class AccountProfilesRepositoryContractIntValue extends ValueObject<int> {
  AccountProfilesRepositoryContractIntValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  factory AccountProfilesRepositoryContractIntValue.fromRaw(
    Object? raw, {
    int defaultValue = 0,
    bool isRequired = true,
  }) {
    final value = AccountProfilesRepositoryContractIntValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is int) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  int doParse(String? parseValue) {
    final parsed = int.tryParse((parseValue ?? '').trim());
    if (parsed == null || parsed < 0) {
      return defaultValue;
    }
    return parsed;
  }
}
