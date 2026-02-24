import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
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

  final StreamValue<bool?> loginResultStreamValue = StreamValue<bool?>();
  final StreamValue<bool?> signUpResultStreamValue = StreamValue<bool?>();

  bool get isAuthorized => _authRepository.isAuthorized;
  bool get isLandlordContext {
    if (_appData.typeValue.value == EnvironmentType.landlord) {
      return true;
    }
    final landlordHost = _resolveLandlordHost(BellugaConstants.landlordDomain);
    return landlordHost != null && _appData.hostname == landlordHost;
  }

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

  void clearGeneralError() {
    generalErrorStreamValue.addValue(null);
  }

  bool validate() => loginFormKey.currentState?.validate() ?? false;

  void resetSignupControllers() {
    signupNameController.clear();
    signupEmailController.clear();
    signupPasswordController.clear();
  }

  Future<void> submitSignup() async {
    _cleanAllErrors();

    final normalizedName = signupNameController.text.trim();
    final normalizedEmail = signupEmailController.text.trim();
    final normalizedPassword = signupPasswordController.text.trim();

    if (normalizedName.isEmpty ||
        normalizedEmail.isEmpty ||
        normalizedPassword.isEmpty) {
      generalErrorStreamValue.addValue('Preencha todos os campos.');
      signUpResultStreamValue.addValue(false);
      return;
    }

    await signUpWithEmailPassword(
      normalizedName,
      normalizedEmail,
      normalizedPassword,
    );
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
      loginResultStreamValue.addValue(_authRepository.isAuthorized);
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
      loginResultStreamValue.addValue(false);
    } catch (e) {
      generalErrorStreamValue.addValue(_resolveUnknownError(e));
      loginResultStreamValue.addValue(false);
    }

    buttonLoadingValue.addValue(false);
    fieldEnabled.addValue(true);
  }

  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    buttonLoadingValue.addValue(true);
    fieldEnabled.addValue(false);
    _cleanAllErrors();

    try {
      await _authRepository.signUpWithEmailPassword(name, email, password);
      final authorized = _authRepository.isAuthorized;
      if (!authorized) {
        generalErrorStreamValue.addValue(
          'Falha ao autenticar após o cadastro.',
        );
      }
      signUpResultStreamValue.addValue(authorized);
    } on BellugaAuthError catch (e) {
      generalErrorStreamValue.addValue(e.message);
      signUpResultStreamValue.addValue(false);
    } catch (e) {
      generalErrorStreamValue.addValue(_resolveUnknownError(e));
      signUpResultStreamValue.addValue(false);
    } finally {
      buttonLoadingValue.addValue(false);
      fieldEnabled.addValue(true);
    }
  }

  void clearLoginResult() {
    loginResultStreamValue.addValue(null);
  }

  void clearSignUpResult() {
    signUpResultStreamValue.addValue(null);
  }

  Future<bool> requestLandlordAdminLogin({
    required Future<bool> Function() performLogin,
  }) async {
    if (!isLandlordContext) {
      return false;
    }
    return performLogin();
  }

  String _resolveUnknownError(Object error) {
    final raw = error.toString();
    final cleaned = raw.replaceFirst(
      RegExp(r'^(Exception|StateError|Error):\s*'),
      '',
    );
    final message = cleaned.trim();
    return message.isEmpty ? 'Erro desconhecido' : message;
  }

  String? _resolveLandlordHost(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.host.trim().isNotEmpty) {
      return uri.host.trim();
    }
    return trimmed;
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
    loginResultStreamValue.dispose();
    signUpResultStreamValue.dispose();
    sliverAppBarController.dispose();
  }
}
