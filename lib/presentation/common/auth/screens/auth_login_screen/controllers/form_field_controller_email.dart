import 'package:belluga_now/presentation/tenant/auth/login/controllers/form_field_controller_contract.dart';
import 'package:belluga_now/presentation/common/auth/value_objects/auth_email_address_value.dart';
import 'package:value_object_pattern/domain/exceptions/value_exceptions.dart';

class FormFieldControllerEmail extends FormFieldControllerContract<String> {
  FormFieldControllerEmail({super.initialValue});

  @override
  final valueObject = AuthEmailAddressValue();

  @override
  String errorToString(ValueException error) {
    return switch (error.runtimeType) {
      const (InvalidValueException) => "Email inválido",
      const (RequiredValueException) => "Email obrigatório",
      _ => "Erro ao salvar: $text",
    };
  }
}
