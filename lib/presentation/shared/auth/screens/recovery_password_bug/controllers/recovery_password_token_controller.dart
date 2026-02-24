import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/form_field_controller_email.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/recovery_password_token_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class AuthRecoveryPasswordController
    implements AuthRecoveryPasswordControllerContract {
  AuthRecoveryPasswordController();

  @override
  final formKey = GlobalKey<FormState>();

  @override
  final emailController = FormFieldControllerEmail();

  @override
  final loading = StreamValue<bool>(defaultValue: false);

  @override
  final error = StreamValue<String>(defaultValue: '');

  @override
  final List<TextEditingController> tokenControllers =
      List<TextEditingController>.generate(6, (_) => TextEditingController());

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
  void attachInitialEmail(String? initialEmail) {
    if (initialEmail?.isNotEmpty ?? false) {
      emailController.textController.text = initialEmail!;
    } else {
      emailController.textController.clear();
    }
  }

  @override
  void onDispose() {
    emailController.dispose();
    loading.dispose();
    error.dispose();
    for (final controller in tokenControllers) {
      controller.dispose();
    }
  }
}
