import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/widget_keys.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/auth_login_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/widgets/auth_email_field.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/widgets/auth_password_field.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthLoginnForm extends StatelessWidget {
  const AuthLoginnForm({super.key});

  @override
  Widget build(BuildContext context) {
    final _controller = GetIt.I.get<AuthLoginControllerContract>();

    return Form(
      key: _controller.loginFormKey,
      child: StreamValueBuilder<bool>(
        streamValue: _controller.fieldEnabled,
        builder: (context, fieldEnabled) {
          return Column(
            children: [
              AuthEmailField(
                key: WidgetKeys.auth.loginEmailField,
                formFieldController: _controller.emailController,
                isEnabled: fieldEnabled,
              ),
              const SizedBox(height: 35),
              AuthPasswordField(
                key: WidgetKeys.auth.loginPasswordField,
                formFieldController: _controller.passwordController,
                isEnabled: fieldEnabled,
              )
            ],
          );
        }
      ),
    );
  }
}
