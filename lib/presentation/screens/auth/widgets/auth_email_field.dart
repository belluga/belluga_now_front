import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/widgets/auth_email_contract.dart';

class AuthEmailField extends FormFieldBelluga {
  const AuthEmailField({
    super.key,
    required super.formFieldController,
  });

  @override
  String get label => "Email";

  @override
  TextInputType get inputType => TextInputType.emailAddress;
}
