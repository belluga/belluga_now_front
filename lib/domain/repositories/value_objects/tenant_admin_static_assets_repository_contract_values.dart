import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';
import 'package:value_object_pattern/value_object.dart';

class TenantAdminStaticAssetsRepositoryContractTextValue
    extends GenericStringValue {
  TenantAdminStaticAssetsRepositoryContractTextValue({
    super.defaultValue = '',
    super.isRequired = false,
    super.maxLenght,
    super.minLenght,
  });

  factory TenantAdminStaticAssetsRepositoryContractTextValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = false,
  }) {
    final value = TenantAdminStaticAssetsRepositoryContractTextValue(
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

class TenantAdminStaticAssetsRepositoryContractIntValue
    extends ValueObject<int> {
  TenantAdminStaticAssetsRepositoryContractIntValue({
    super.defaultValue = 0,
    super.isRequired = true,
  });

  factory TenantAdminStaticAssetsRepositoryContractIntValue.fromRaw(
    Object? raw, {
    int defaultValue = 0,
    bool isRequired = true,
  }) {
    final value = TenantAdminStaticAssetsRepositoryContractIntValue(
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

class TenantAdminStaticAssetsRepositoryContractBoolValue
    extends ValueObject<bool> {
  TenantAdminStaticAssetsRepositoryContractBoolValue({
    super.defaultValue = false,
    super.isRequired = true,
  });

  factory TenantAdminStaticAssetsRepositoryContractBoolValue.fromRaw(
    Object? raw, {
    bool defaultValue = false,
    bool isRequired = true,
  }) {
    final value = TenantAdminStaticAssetsRepositoryContractBoolValue(
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

List<TenantAdminStaticAssetsRepositoryContractTextValue>
    tenantAdminStaticAssetsRepoTextListFromRaw(
  Iterable<String> rawValues,
) {
  return rawValues
      .map(TenantAdminStaticAssetsRepositoryContractTextValue.fromRaw)
      .toList(growable: false);
}

List<String> tenantAdminStaticAssetsRepoRawTextList(
  Iterable<TenantAdminStaticAssetsRepositoryContractTextValue> values,
) {
  return values.map((value) => value.value).toList(growable: false);
}
