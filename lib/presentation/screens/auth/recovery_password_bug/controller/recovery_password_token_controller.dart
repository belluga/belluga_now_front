import 'package:flutter/material.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/controllers/recovery_password_token_controller_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/domain/repositories/auth_repository_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/presentation/screens/auth/login/controller/form_field_controller_email.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class AuthRecoveryPasswordController
    implements AuthRecoveryPasswordControllerContract {
  AuthRecoveryPasswordController({String? initialEmail}) {
    if (initialEmail != null) {
      emailController.textController.text = initialEmail;
    }
  }

  @override
  final formKey = GlobalKey<FormState>();

  @override
  final emailController = FormFieldControllerEmail();

  @override
  final loading = StreamValue<bool>(defaultValue: false);

  @override
  final error = StreamValue<String>(defaultValue: '');

  final _authRepository = GetIt.I<AuthRepositoryContract>();

  String? codigoEnviado;

  Stream<String?> get generalErrorStreamValue => error.stream;

  @override
  bool validate() => formKey.currentState?.validate() ?? false;

  @override
  Future<void> submit() async {
    loading.addValue(true);
    error.addValue(null);
    emailController.cleanError();

    try {
      if (validate()) {
        await _authRepository.sendTokenRecoveryPassword(
          emailController.value,
          codigoEnviado!,
        );
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
