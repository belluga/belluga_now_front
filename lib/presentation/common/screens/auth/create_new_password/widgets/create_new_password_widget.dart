import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/domain/controllers/create_password_controller_contract.dart';
import 'package:belluga_now/presentation/common/screens/auth/create_new_password/widgets/new_password_box_widget.dart';
import 'package:belluga_now/presentation/common/screens/auth/create_new_password/widgets/confirm_password_box_widget.dart';
import 'package:get_it/get_it.dart';

class CreateNewPasswordWidget extends StatelessWidget {
  const CreateNewPasswordWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final _controller = GetIt.I.get<CreatePasswordControllerContract>();

    return Form(
      key: _controller.newPasswordFormKey,
      child: StreamBuilder<bool>(
        stream: _controller.fieldEnabled.stream,
        builder: (context, fieldEnabled) {
          return Column(
            children: [
              const SizedBox(height: 20),
              NewPasswordBoxWidget(
                key: WidgetKeys.auth.newPasswordField,
                formFieldController: _controller.newPasswordController,
                isEnabled: fieldEnabled.data ?? true,
              ),
              const SizedBox(height: 40),
              ConfirmPasswordBoxWidget(
                key: WidgetKeys.auth.newPasswordConfirmField,
                formFieldController: _controller.confirmPasswordController,
                isEnabled: fieldEnabled.data ?? true,
              ),
            ],
          );
        },
      ),
    );
  }
}
