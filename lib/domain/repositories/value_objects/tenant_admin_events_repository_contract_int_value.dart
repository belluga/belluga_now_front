import 'package:value_object_pattern/value_object.dart';

class TenantAdminEventsRepositoryContractIntValue extends ValueObject<int> {
  TenantAdminEventsRepositoryContractIntValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  factory TenantAdminEventsRepositoryContractIntValue.fromRaw(
    Object? raw, {
    int defaultValue = 0,
    bool isRequired = true,
  }) {
    final value = TenantAdminEventsRepositoryContractIntValue(
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
