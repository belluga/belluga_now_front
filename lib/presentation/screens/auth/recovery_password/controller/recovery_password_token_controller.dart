import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/recovery_password_token_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/controller/form_field_controller_email.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class AuthRecoveryPasswordController  implements AuthRecoveryPasswordControllerContract{
  @override
  final formKey = GlobalKey<FormState>();
  
  @override
  final emailController = FormFieldControllerEmail();

  @override
  final loading = StreamValue<bool>(defaultValue: false);
  
  @override
  final error =  StreamValue<String>();

  final _authRepository = GetIt.I<AuthRepositoryContract>();

  @override
  bool validate() => formKey.currentState?.validate() ?? false;

  @override
  Future<void> submit() async {
    loading.addValue(true);
    error.addValue(null);
    emailController.cleanError();

    try {
      if (validate()) {
        await GetIt.I<AuthRepositoryContract>().sendTokenRecoveryPassword(emailController.value);
        // Simulate a successful response
      }
    } catch (e) {
      error.addValue("Erro ao enviar o email de recuperação de senha.");
    }

    loading.addValue(false);
  }

  @override
  void onDispose() {
    emailController.dispose();
    loading.dispose();
    error.dispose();
  }
}