import 'package:flutter_laravel_backend_boilerplate/domain/controllers/create_password_controller_contract.dart';

class CreatePasswordController extends CreatePasswordControllerContract{
  CreatePasswordController({
    super.newPassword,
    super.confirmPassword,
  });

  @override
  void onDispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    buttonLoadingValue.dispose();
    fieldEnabled.dispose();
    generalErrorStreamValue.dispose();
  }
}