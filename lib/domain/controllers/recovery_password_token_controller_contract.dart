import 'package:flutter/material.dart';
import 'package:belluga_now/presentation/screens/auth/login/controller/form_field_controller_email.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AuthRecoveryPasswordControllerContract {
  GlobalKey<FormState> get formKey;
  FormFieldControllerEmail get emailController;

  StreamValue<bool> get loading;
  StreamValue<String?> get error;

  bool validate();
  Future<void> submit();
  void onDispose();
}
