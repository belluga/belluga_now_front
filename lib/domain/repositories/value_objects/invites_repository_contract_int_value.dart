import 'package:value_object_pattern/value_object.dart';

class InvitesRepositoryContractIntValue extends ValueObject<int> {
  InvitesRepositoryContractIntValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  factory InvitesRepositoryContractIntValue.fromRaw(
    Object? raw, {
    int defaultValue = 0,
    bool isRequired = true,
  }) {
    final value = InvitesRepositoryContractIntValue(
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
