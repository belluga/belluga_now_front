import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_create_new_password_screen/widgets/confirm_password_box_widget.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_create_new_password_screen/widgets/new_password_box_widget.dart';
import 'package:belluga_now/presentation/tenant/auth/login/controllers/create_password_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:stream_value/core/stream_value_builder.dart';

class CreateNewPasswordWidget extends StatefulWidget {
  const CreateNewPasswordWidget({
    super.key,
    required this.controller,
  });

  final CreatePasswordControllerContract controller;

  @override
  State<CreateNewPasswordWidget> createState() =>
      _CreateNewPasswordWidgetState();
}

class _CreateNewPasswordWidgetState extends State<CreateNewPasswordWidget> {
  CreatePasswordControllerContract get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _controller.newPasswordFormKey,
      child: StreamValueBuilder<bool>(
        streamValue: _controller.fieldEnabled,
        builder: (context, isEnabled) {
          return Column(
            children: [
              const SizedBox(height: 20),
              NewPasswordBoxWidget(
                key: WidgetKeys.auth.newPasswordField,
                formFieldController: _controller.newPasswordController,
                isEnabled: isEnabled,
              ),
              const SizedBox(height: 40),
              ConfirmPasswordBoxWidget(
                key: WidgetKeys.auth.newPasswordConfirmField,
                formFieldController: _controller.confirmPasswordController,
                isEnabled: isEnabled,
              ),
            ],
          );
        },
      ),
    );
  }
}
