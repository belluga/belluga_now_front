import 'package:value_objects/domain/value_objects/full_name_value.dart';

class AuthFullNameValue extends FullNameValue {
  AuthFullNameValue({
    super.isRequired = true,
    super.defaultValue = "",
  });
}