import 'package:flutter/material.dart';
import 'package:belluga_now/domain/auth/errors/belluga_auth_errors.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/controllers/form_field_controller_password_login.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class CreatePasswordControllerContract extends Disposable {
  CreatePasswordControllerContract({
    String? newPassword,
    String? confirmPassword,
  }) {
    newPasswordController = FormFieldControllerPasswordLogin(
      initialValue: newPassword,
    );
    confirmPasswordController = FormFieldControllerPasswordLogin(
      initialValue: confirmPassword,
    );
  }

  final _authRepository = GetIt.I.get<AuthRepositoryContract>();

  final newPasswordFormKey = GlobalKey<FormState>();

  final StreamValue<bool> buttonLoadingValue = StreamValue<bool>(
    defaultValue: false,
  );

  final StreamValue<bool> fieldEnabled = StreamValue<bool>(defaultValue: true);

  final generalErrorStreamValue = StreamValue<String?>();

  late FormFieldControllerPasswordLogin newPasswordController;
  late FormFieldControllerPasswordLogin confirmPasswordController;

  void cleanNewPasswordError(_) => newPasswordController.cleanError();
  void cleanConfirmPasswordError(_) => confirmPasswordController.cleanError();

  void _cleanAllErrors() {
    cleanNewPasswordError(null);
    cleanConfirmPasswordError(null);
    generalErrorStreamValue.addValue(null);
  }

  bool validate() => newPasswordFormKey.currentState?.validate() ?? false;

  Future<void> createPassword() async {
    buttonLoadingValue.addValue(true);
    fieldEnabled.addValue(false);

    _cleanAllErrors();

    try {
      if (validate()) {
        if (newPasswordController.value != confirmPasswordController.value) {
          generalErrorStreamValue.addValue("As senhas não são iguais.");
        } else {
          await _authRepository.createNewPassword(
            newPasswordController.value,
            confirmPasswordController.value,
          );
        }
      }
    } on BellugaAuthError catch (e) {
      generalErrorStreamValue.addValue(e.message);
    } catch (e) {
      generalErrorStreamValue.addValue("Erro ao criar a senha.");
    }

    buttonLoadingValue.addValue(false);
    fieldEnabled.addValue(true);
  }
}
