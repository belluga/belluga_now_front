import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

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
