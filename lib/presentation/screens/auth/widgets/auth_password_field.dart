import 'package:flutter/material.dart';
import 'package:unifast_portal/presentation/screens/auth/widgets/form_field_belluga.dart';

class AuthPasswordField extends FormFieldBelluga {
  const AuthPasswordField({
    super.key,
    super.isEnabled,
    required super.formFieldController,
  });

  @override
  String get label => "Senha";

  @override
  String get hint => "Sua senha";

  @override
  TextInputType get inputType => TextInputType.visiblePassword;

  @override
  bool get obscureText => true;
}
