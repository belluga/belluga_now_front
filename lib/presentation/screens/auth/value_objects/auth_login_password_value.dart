import 'package:value_objects/domain/value_objects/password_value.dart';

class AuthLoginPasswordValue extends PasswordValue {
  AuthLoginPasswordValue({
    super.minChar = 6,
    super.mustContainSpecialChar = false,
    super.mustContainNumeric = false,
    super.mustContainLowerChar = false,
    super.mustContainUpperChar = false,
  });
}
