import 'package:flutter/material.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/auth/errors/belluga_auth_errors.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/controllers/form_field_controller_email.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/controllers/form_field_controller_password_login.dart';
import 'package:belluga_now/presentation/common/auth/screens/auth_login_screen/controllers/sliver_app_bar_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class AuthLoginControllerContract extends Object with Disposable {
  AuthLoginControllerContract({
    AuthRepositoryContract? authRepository,
    String? initialEmail,
    String? initialPassword,
  }) : _authRepository =
            authRepository ?? GetIt.I.get<AuthRepositoryContract>() {
    authEmailFieldController = FormFieldControllerEmail(
      initialValue: initialEmail,
    );

    passwordController = FormFieldControllerPasswordLogin(
      initialValue: initialPassword,
    );
  }

  final AuthRepositoryContract _authRepository;
  final AppData _appData = GetIt.I.get<AppData>();

  final sliverAppBarController = SliverAppBarController();

  StreamValue<UserBelluga> get userBelluga =>
      _authRepository.userStreamValue as StreamValue<UserBelluga>;
  AppData get appData => _appData;

  final loginFormKey = GlobalKey<FormState>();

  final StreamValue<bool> buttonLoadingValue = StreamValue<bool>(
    defaultValue: false,
  );

  final StreamValue<bool> fieldEnabled = StreamValue<bool>(defaultValue: true);

  bool get isAuthorized => _authRepository.isAuthorized;

  late FormFieldControllerEmail authEmailFieldController;

  late FormFieldControllerPasswordLogin passwordController;

  final TextEditingController signupNameController = TextEditingController();
  final TextEditingController signupEmailController = TextEditingController();
  final TextEditingController signupPasswordController =
      TextEditingController();

  final generalErrorStreamValue = StreamValue<String?>();

  void cleanEmailError(Object? _) => authEmailFieldController.cleanError();
  void cleanPasswordError(Object? _) => passwordController.cleanError();

  void _cleanAllErrors() {
    cleanEmailError(null);
    cleanPasswordError(null);
    generalErrorStreamValue.addValue(null);
  }

  bool validate() => loginFormKey.currentState?.validate() ?? false;

  void resetSignupControllers() {
    signupNameController.clear();
    signupEmailController.clear();
    signupPasswordController.clear();
  }

  Future<void> tryLoginWithEmailPassword() async {
    buttonLoadingValue.addValue(true);
    fieldEnabled.addValue(false);

    _cleanAllErrors();

    try {
      if (validate()) {
        await _authRepository.loginWithEmailPassword(
          authEmailFieldController.value,
          passwordController.value,
        );
      }
    } on BellugaAuthError catch (e) {
      switch (e.runtimeType) {
        case const (AuthErrorEmail):
          authEmailFieldController.addError(e.message);
          break;
        case const (AuthErrorPassword):
          passwordController.addError(e.message);
          break;
        default:
          generalErrorStreamValue.addValue(e.message);
      }
    } catch (e) {
      generalErrorStreamValue.addValue("Erro desconhecido");
    }

    buttonLoadingValue.addValue(false);
    fieldEnabled.addValue(true);
  }

  Future<bool> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    buttonLoadingValue.addValue(true);
    fieldEnabled.addValue(false);
    _cleanAllErrors();

    try {
      await _authRepository.signUpWithEmailPassword(name, email, password);
      return _authRepository.isAuthorized;
    } on BellugaAuthError catch (e) {
      generalErrorStreamValue.addValue(e.message);
      return false;
    } catch (e) {
      generalErrorStreamValue.addValue("Erro desconhecido");
      return false;
    } finally {
      buttonLoadingValue.addValue(false);
      fieldEnabled.addValue(true);
    }
  }

  @override
  void onDispose() {
    authEmailFieldController.dispose();
    passwordController.dispose();
    signupNameController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    generalErrorStreamValue.dispose();
    buttonLoadingValue.dispose();
  }
}
