import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminOrganizationsRepositoryContractTextValue
    extends GenericStringValue {
  TenantAdminOrganizationsRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory TenantAdminOrganizationsRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = TenantAdminOrganizationsRepositoryContractTextValue(
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

class TenantAdminOrganizationsRepositoryContractIntValue
    extends ValueObject<int> {
  TenantAdminOrganizationsRepositoryContractIntValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  factory TenantAdminOrganizationsRepositoryContractIntValue.fromRaw(
    Object? raw, {
    int defaultValue = 0,
    bool isRequired = true,
  }) {
    final value = TenantAdminOrganizationsRepositoryContractIntValue(
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

class TenantAdminOrganizationsRepositoryContractBoolValue
    extends ValueObject<bool> {
  TenantAdminOrganizationsRepositoryContractBoolValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  factory TenantAdminOrganizationsRepositoryContractBoolValue.fromRaw(
    Object? raw, {
    bool defaultValue = false,
    bool isRequired = true,
  }) {
    final value = TenantAdminOrganizationsRepositoryContractBoolValue(
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
