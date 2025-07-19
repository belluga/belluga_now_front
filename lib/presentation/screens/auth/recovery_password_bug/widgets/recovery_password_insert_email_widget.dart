import 'package:flutter/material.dart';
import 'package:unifast_portal/application/configurations/widget_keys.dart';
import 'package:unifast_portal/domain/controllers/recovery_password_token_controller_contract.dart';
import 'package:unifast_portal/presentation/screens/auth/recovery_password_bug/controller/recovery_password_token_controller.dart';
import 'package:unifast_portal/presentation/screens/auth/widgets/auth_email_field.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class RecoveryPasswordInsertEmailWidget extends StatefulWidget {
  const RecoveryPasswordInsertEmailWidget({super.key});

  @override
  State<RecoveryPasswordInsertEmailWidget> createState() =>
      _RecoveryPasswordInsertEmailWidgetState();
}

class _RecoveryPasswordInsertEmailWidgetState
    extends State<RecoveryPasswordInsertEmailWidget> {
  final _controller = GetIt.I
      .registerSingleton<AuthRecoveryPasswordControllerContract>(
        AuthRecoveryPasswordController(),
      );

  @override
  Widget build(BuildContext context) {
    return StreamValueBuilder<bool>(
      streamValue: _controller.loading,
      builder: (context, fieldEnabled) {
        return Form(
          key: _controller.formKey,
          child: AuthEmailField(
            key: WidgetKeys.auth.loginEmailField,
            formFieldController: _controller.emailController,
            isEnabled: fieldEnabled,
          ),
        );
      },
    );
  }
}
