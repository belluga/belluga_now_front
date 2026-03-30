import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

class AuthErrorMessageValue extends GenericStringValue {
  AuthErrorMessageValue({
    String raw = '',
    super.isRequired = false,
  }) : super(defaultValue: '') {
    parse(raw);
  }
}
