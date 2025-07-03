import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/widgets/form_field_belluga.dart';

class AuthEmailField extends FormFieldBelluga {
  const AuthEmailField({
    super.key,
    super.isEnabled,
    required super.formFieldController,
  });

 @override
  String get label => "Email";

  @override
  String get hint => "Seu email";

  @override
  TextInputType get inputType => TextInputType.emailAddress;
}

