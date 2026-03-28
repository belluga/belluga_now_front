import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminEventsRepositoryContractTextValue extends GenericStringValue {
  TenantAdminEventsRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory TenantAdminEventsRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = TenantAdminEventsRepositoryContractTextValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
    );
    final normalized = (raw as String?)?.trim();
    value.parse(normalized);
    return value;
  }

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim();
  }
}

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
