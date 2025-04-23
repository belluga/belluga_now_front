import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/user/user_belluga.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/controller/form_field_controller_email.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/controller/form_field_controller_password_login.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AuthLoginControllerContract extends Disposable{
  AuthLoginControllerContract({
    String? initialEmail,
    String? initialPassword,
  }) {
    emailController = FormFieldControllerEmail(initialValue: initialEmail);
    passwordController =
        FormFieldControllerPasswordLogin(initialValue: initialPassword);
  }

  final _authRepository = GetIt.I.get<AuthRepositoryContract>();

  StreamValue<UserBelluga> get userBelluga =>
      _authRepository.userStreamValue as StreamValue<UserBelluga>;
  
  final loginFormKey = GlobalKey<FormState>();

  final StreamValue<bool> buttonLoadingValue = StreamValue<bool>(defaultValue: false);

  final StreamValue<bool> fieldEnabled = StreamValue<bool>(defaultValue: true);

  bool get isAuthorized => _authRepository.isAuthorized;

  late FormFieldControllerEmail emailController;

  late FormFieldControllerPasswordLogin passwordController;

  final generalErrorStreamValue = StreamValue<String?>();

  void cleanEmailError(_) => emailController.cleanError();
  void cleanPasswordError(_) => passwordController.cleanError();

  void _cleanAllErrors() {
    cleanEmailError(null);
    cleanPasswordError(null);
    generalErrorStreamValue.addValue(null);
  }

  bool validate() => loginFormKey.currentState?.validate() ?? false;

  Future<void> tryLoginWithEmailPassword() async {
    buttonLoadingValue.addValue(true);
    fieldEnabled.addValue(false);

    _cleanAllErrors();

    try {
      if (validate()) {
        await _authRepository.loginWithEmailPassword(
          emailController.value,
          passwordController.value,
        );
      }
    // } on BellugaAuthError catch (e) {
    //   switch (e.runtimeType) {
    //     case const (AuthErrorInvalidEmail):
    //       emailController.addError("Email inválido");
    //       break;
    //     case const (AuthErrorUserAlreadyExists):
    //       emailController.addError("Email já cadastrado");
    //       break;
    //     case const (AuthErrorPasswordWeak):
    //       passwordController.addError("Senha fraca");
    //       break;
    //     case const (AuthErrorOperationNotAllowed):
    //       generalErrorStreamValue.addValue("Operação não autorizada");
    //       break;
    //     case const (AuthErrorInvalidCredentials):
    //       generalErrorStreamValue.addValue("Usuário OU senha incorretos");
    //       break;
    //     default:
    //       generalErrorStreamValue.addValue("Erro desconhecido");
    //       "Erro desconhecido";
    //   }
    } catch (e) {
      generalErrorStreamValue.addValue("Erro desconhecido");  
    }

    buttonLoadingValue.addValue(false);
    fieldEnabled.addValue(true);
  }

  @override
  void onDispose() {
    emailController.dispose();
    passwordController.dispose();
    generalErrorStreamValue.dispose();
    buttonLoadingValue.dispose();
  }
}
