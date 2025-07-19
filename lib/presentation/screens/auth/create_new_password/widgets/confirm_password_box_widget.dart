import 'package:flutter/material.dart';
import 'package:unifast_portal/presentation/screens/auth/widgets/form_field_belluga.dart';

class ConfirmPasswordBoxWidget extends FormFieldBelluga {
  const ConfirmPasswordBoxWidget({
    super.key,
    super.isEnabled,
    required super.formFieldController,
  });

  @override
  String get label => "Confirmar senha";

  @override
  String get hint => "Sua senha";

  @override
  TextInputType get inputType => TextInputType.visiblePassword;

  @override
  bool get obscureText => true;
}
