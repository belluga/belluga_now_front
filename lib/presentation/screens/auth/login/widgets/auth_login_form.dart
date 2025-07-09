import 'package:flutter/material.dart';
import 'package:unifast_portal/application/configurations/widget_keys.dart';
import 'package:unifast_portal/domain/controllers/auth_login_controller_contract.dart';
import 'package:unifast_portal/presentation/screens/auth/widgets/auth_email_field.dart';
import 'package:unifast_portal/presentation/screens/auth/widgets/auth_password_field.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class AuthLoginnForm extends StatelessWidget {
  final _controller = GetIt.I.get<AuthLoginControllerContract>();

  AuthLoginnForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _controller.loginFormKey,
      child: StreamValueBuilder<bool>(
        streamValue: _controller.fieldEnabled,
        builder: (context, fieldEnabled) {
          return Column(
            children: [
              AuthEmailField(
                key: WidgetKeys.auth.loginEmailField,
                formFieldController: _controller.authEmailFieldController,
                isEnabled: fieldEnabled,
              ),
              const SizedBox(height: 30),
              AuthPasswordField(
                key: WidgetKeys.auth.loginPasswordField,
                formFieldController: _controller.passwordController,
                isEnabled: fieldEnabled,
              ),
            ],
          );
        },
      ),
    );
  }
}
