import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class TenantLookupDomainValue extends GenericStringValue {
  TenantLookupDomainValue({
    super.defaultValue = '',
    super.isRequired = true,
    super.minLenght = 1,
  });

  @override
  String doParse(String? parseValue) {
    return (parseValue ?? '').trim().toLowerCase();
  }

  factory TenantLookupDomainValue.fromRaw(
    Object? raw, {
    String defaultValue = '',
    bool isRequired = true,
  }) {
    final value = TenantLookupDomainValue(
      defaultValue: defaultValue,
      isRequired: isRequired,
      minLenght: 1,
    );
    value.parse(raw?.toString());
    return value;
  }
}
