import 'package:value_object_pattern/value_object.dart';

class TenantAdminEventsRepositoryContractBoolValue extends ValueObject<bool> {
  TenantAdminEventsRepositoryContractBoolValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  factory TenantAdminEventsRepositoryContractBoolValue.fromRaw(
    Object? raw, {
    bool defaultValue = false,
    bool isRequired = true,
  }) {
    final value = TenantAdminEventsRepositoryContractBoolValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    if (raw is bool) {
      value.set(raw);
      return value;
    }
    value.parse(raw?.toString());
    return value;
  }

  @override
  bool doParse(String? parseValue) {
    final normalized = (parseValue ?? '').trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') {
      return true;
    }
    if (normalized == 'false' || normalized == '0') {
      return false;
    }
    return defaultValue;
  }
}
