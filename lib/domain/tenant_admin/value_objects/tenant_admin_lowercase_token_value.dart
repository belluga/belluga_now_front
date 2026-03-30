import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class TenantAdminLowercaseTokenValue extends GenericStringValue {
  TenantAdminLowercaseTokenValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 1,
  });

  @override
  String doParse(String? parseValue) => (parseValue ?? '').trim().toLowerCase();

  factory TenantAdminLowercaseTokenValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = true,
  }) {
    final value = TenantAdminLowercaseTokenValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
      minLenght: 1,
    );
    value.parse(raw?.toString());
    return value;
  }
}
