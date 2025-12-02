import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/presentation/common/auth/widgets/auth_email_field.dart';
import 'package:belluga_now/presentation/common/auth/widgets/auth_password_field.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthLoginForm extends StatefulWidget {
  const AuthLoginForm({super.key}) : controller = null;

  @visibleForTesting
  const AuthLoginForm.withController(
    this.controller, {
    super.key,
  });

  final AuthLoginControllerContract? controller;

  @override
  State<AuthLoginForm> createState() => _AuthLoginFormState();
}

class _AuthLoginFormState extends State<AuthLoginForm> {
  AuthLoginControllerContract get _controller =>
      widget.controller ?? GetIt.I.get<AuthLoginControllerContract>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _controller.loginFormKey,
      child: StreamValueBuilder<bool>(
        streamValue: _controller.fieldEnabled,
        builder: (context, fieldEnabled) {
          final isEnabled = fieldEnabled;
          return Column(
            children: [
              AuthEmailField(
                key: WidgetKeys.auth.loginEmailField,
                formFieldController: _controller.authEmailFieldController,
                isEnabled: isEnabled,
              ),
              const SizedBox(height: 30),
              AuthPasswordField(
                key: WidgetKeys.auth.loginPasswordField,
                formFieldController: _controller.passwordController,
                isEnabled: isEnabled,
              ),
            ],
          );
        },
      ),
    );
  }
}
