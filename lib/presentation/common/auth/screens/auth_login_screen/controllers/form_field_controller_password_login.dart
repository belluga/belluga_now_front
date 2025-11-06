import 'package:belluga_now/presentation/tenant/auth/login/controllers/form_field_controller_contract.dart';
import 'package:belluga_now/presentation/common/auth/value_objects/auth_login_password_value.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';

class FormFieldControllerPasswordLogin
    extends FormFieldControllerContract<String> {
  FormFieldControllerPasswordLogin({super.initialValue});

  @override
  final valueObject = AuthLoginPasswordValue();

  @override
  String errorToString(ValueException error) {
    return switch (error.runtimeType) {
      const (MustContainLowerValueException) =>
        "Precisa conter letra minúscula",
      const (MustContainNumberValueException) => "Precisa conter algum número",
      const (MustContainUpperValueException) =>
        "Precisa conter letra MAIÚSCULA",
      const (MustContainSpecialValueException) =>
        "Precisa conter caracter especial ( - * _ )",
      const (TooShortValueException) => "Senha muito curta",
      const (TooLongValueException) => "Senha muito longa",
      const (InvalidValueException) => "Senha inválida",
      const (RequiredValueException) => "Senha obigatória",
      _ => "Senha inválida",
    };
  }
}
