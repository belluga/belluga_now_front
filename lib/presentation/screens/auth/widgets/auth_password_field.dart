import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/widgets/auth_email_contract.dart';

class AuthPasswordField extends FormFieldBelluga {
  const AuthPasswordField({
    super.key,
    super.isEnabled,
    required super.formFieldController,
  });

  @override
  String get label => "Sua senha";

  @override
  TextInputType get inputType => TextInputType.visiblePassword;

  @override
  bool get obscureText => true;
}
