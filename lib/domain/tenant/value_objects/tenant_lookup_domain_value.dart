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
}
