import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AppDomainValue extends GenericStringValue {
  AppDomainValue({
    super.defaultValue,
    super.isRequired = true,
  });
}
