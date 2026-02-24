import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/form_field_controller_email.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart' show Disposable;
import 'package:stream_value/core/stream_value.dart';

abstract class AuthRecoveryPasswordControllerContract extends Disposable {
  GlobalKey<FormState> get formKey;
  FormFieldControllerEmail get emailController;

  StreamValue<bool> get loading;
  StreamValue<String?> get error;
  List<TextEditingController> get tokenControllers;

  bool validate();
  Future<void> submit();
  void attachInitialEmail(String? initialEmail);
}
