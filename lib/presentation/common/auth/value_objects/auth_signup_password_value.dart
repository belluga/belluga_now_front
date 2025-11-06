import 'package:value_object_pattern/domain/value_objects/password_value.dart';

class AuthSignupPasswordValue extends PasswordValue {
  AuthSignupPasswordValue({super.mustContainSpecialChar = true});
}
