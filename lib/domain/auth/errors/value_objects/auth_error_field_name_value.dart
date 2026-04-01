import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AuthErrorFieldNameValue extends GenericStringValue {
  AuthErrorFieldNameValue({
    String raw = '',
    super.isRequired = true,
  }) : super(defaultValue: '', minLenght: 1) {
    parse(raw);
  }
}
