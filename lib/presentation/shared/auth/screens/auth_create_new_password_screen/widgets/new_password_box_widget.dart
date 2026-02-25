import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/shared/auth/widgets/form_field_belluga.dart';

class NewPasswordBoxWidget extends FormFieldBelluga {
  const NewPasswordBoxWidget({
    super.key,
    super.isEnabled,
    required super.formFieldController,
  });

  @override
  String get label => "Senha";

  @override
  String get hint => "Nova senha";

  @override
  TextInputType get inputType => TextInputType.visiblePassword;

  @override
  bool get obscureText => true;
}
