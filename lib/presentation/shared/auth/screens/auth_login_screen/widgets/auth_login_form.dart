import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/presentation/shared/auth/widgets/auth_email_field.dart';
import 'package:belluga_now/presentation/shared/auth/widgets/auth_password_field.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthLoginForm extends StatelessWidget {
  const AuthLoginForm({
    super.key,
    required this.controller,
  });

  final AuthLoginControllerContract controller;

  AuthLoginControllerContract get _controller => controller;

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
              Semantics(
                identifier: 'auth_login_email_field',
                textField: true,
                child: AuthEmailField(
                  key: WidgetKeys.auth.loginEmailField,
                  formFieldController: _controller.authEmailFieldController,
                  isEnabled: isEnabled,
                ),
              ),
              const SizedBox(height: 30),
              Semantics(
                identifier: 'auth_login_password_field',
                textField: true,
                child: AuthPasswordField(
                  key: WidgetKeys.auth.loginPasswordField,
                  formFieldController: _controller.passwordController,
                  isEnabled: isEnabled,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
