import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/application/configurations/widget_keys.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/recovery_password/controller/recovery_password_token_controller.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/widgets/auth_email_field.dart';
import 'package:stream_value/core/stream_value_builder.dart';


class RecoveryPasswordInsertEmailWidget extends StatelessWidget{
  final AuthRecoveryPasswordController controller;

  const RecoveryPasswordInsertEmailWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
      return StreamValueBuilder<bool>(
        streamValue: controller.loading,
        builder: (context, fieldEnabled) {
          return Form(
            key: controller.formKey,
            child: AuthEmailField(
              key: WidgetKeys.auth.loginEmailField,
              formFieldController: controller.emailController,
              isEnabled: fieldEnabled,  
            ),
        );
        },
      );
  }
}