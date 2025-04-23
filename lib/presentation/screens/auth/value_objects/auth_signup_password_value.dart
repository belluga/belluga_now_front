import 'package:value_objects/domain/value_objects/password_value.dart';

class AuthSignupPasswordValue extends PasswordValue {
  AuthSignupPasswordValue({super.mustContainSpecialChar = true});
}
