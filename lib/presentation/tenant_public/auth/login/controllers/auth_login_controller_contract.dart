import 'package:flutter/material.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/environment_type.dart';
import 'package:belluga_now/domain/auth/auth_phone_otp_challenge.dart';
import 'package:belluga_now/domain/auth/errors/belluga_auth_errors.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_text_value.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/form_field_controller_email.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/form_field_controller_password_login.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/sliver_app_bar_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:stream_value/core/stream_value.dart';

enum AuthPhoneOtpStep {
  phoneEntry,
  otpVerification,
}

abstract class AuthLoginControllerContract extends Object with Disposable {
  static const phoneOtpDeliveryChannelWhatsapp = 'whatsapp';
  static const phoneOtpDeliveryChannelSms = 'sms';

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
  final phoneOtpFormKey = GlobalKey<FormState>();
  final otpCodeFormKey = GlobalKey<FormState>();

  final StreamValue<bool> buttonLoadingValue = StreamValue<bool>(
    defaultValue: false,
  );

  final StreamValue<bool> fieldEnabled = StreamValue<bool>(defaultValue: true);

  final StreamValue<bool?> loginResultStreamValue = StreamValue<bool?>();
  final StreamValue<bool?> signUpResultStreamValue = StreamValue<bool?>();
  final StreamValue<AuthPhoneOtpStep> phoneOtpStepStreamValue =
      StreamValue<AuthPhoneOtpStep>(
    defaultValue: AuthPhoneOtpStep.phoneEntry,
  );
  final StreamValue<AuthPhoneOtpChallenge?>
      currentPhoneOtpChallengeStreamValue =
      StreamValue<AuthPhoneOtpChallenge?>();

  bool get isAuthorized => _authRepository.isAuthorized;
  bool get isPhoneOtpSmsFallbackAvailable =>
      _appData.phoneOtpSmsFallbackEnabled;
  bool get isLandlordContext {
    if (_appData.typeValue.value == EnvironmentType.landlord) {
      return true;
    }
    if (_appData.appType != AppType.web) {
      return false;
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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpCodeController = TextEditingController();
  final PhoneController phoneNumberController = PhoneController(
    initialValue: const PhoneNumber(isoCode: IsoCode.BR, nsn: ''),
  );
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode otpCodeFocusNode = FocusNode();

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
  bool validatePhoneForm() {
    final state = phoneOtpFormKey.currentState;
    if (state != null) {
      return state.validate();
    }

    if (phoneNumberController.value.nsn.trim().isNotEmpty) {
      return validatePhoneNumberValue(phoneNumberController.value) == null;
    }
    return validatePhoneInput(phoneController.text) == null;
  }

  bool validateOtpCodeForm() {
    final state = otpCodeFormKey.currentState;
    if (state != null) {
      return state.validate();
    }

    return validateOtpCode(otpCodeController.text) == null;
  }

  String? validatePhoneInput(String? raw) {
    final value = (raw ?? '').trim();
    final digits = value.replaceAll(RegExp(r'\D+'), '');
    if (digits.length < 10) {
      return 'Informe um telefone valido.';
    }
    if (digits.length > 15) {
      return 'O telefone informado e muito longo.';
    }

    return null;
  }

  String? validatePhoneNumberValue(PhoneNumber? phoneNumber) {
    if (phoneNumber == null || phoneNumber.nsn.trim().isEmpty) {
      return 'Informe seu telefone.';
    }
    if (!phoneNumber.isValid()) {
      return 'Informe um telefone valido.';
    }

    return null;
  }

  String? validateOtpCode(String? raw) {
    final value = (raw ?? '').trim();
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'Informe o codigo de 6 digitos.';
    }

    return null;
  }

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
          _authTextValue(authEmailFieldController.value),
          _authTextValue(passwordController.value),
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

  void updatePhoneOtpInput(PhoneNumber phoneNumber) {
    phoneController.text = phoneNumber.international;
  }

  Future<void> requestPhoneOtpChallenge({
    String deliveryChannel = phoneOtpDeliveryChannelWhatsapp,
  }) async {
    if (buttonLoadingValue.value || !fieldEnabled.value) {
      return;
    }

    final normalizedDeliveryChannel =
        deliveryChannel.trim().toLowerCase().isEmpty
            ? phoneOtpDeliveryChannelWhatsapp
            : deliveryChannel.trim().toLowerCase();

    buttonLoadingValue.addValue(true);
    fieldEnabled.addValue(false);
    _cleanAllErrors();

    try {
      if (normalizedDeliveryChannel == phoneOtpDeliveryChannelSms &&
          !isPhoneOtpSmsFallbackAvailable) {
        generalErrorStreamValue.addValue(
          'SMS indisponivel para este ambiente.',
        );
        return;
      }

      if (!validatePhoneForm()) {
        return;
      }

      final phone = _normalizedPhoneForOtpChallenge();
      phoneController.text = phone;
      final challenge = await _authRepository.requestPhoneOtpChallenge(
        _authTextValue(phone),
        deliveryChannel: _authTextValue(normalizedDeliveryChannel),
      );
      currentPhoneOtpChallengeStreamValue.addValue(challenge);
      phoneController.text = challenge.phone;
      _syncPhoneNumberController(challenge.phone);
      otpCodeController.clear();
      phoneOtpStepStreamValue.addValue(AuthPhoneOtpStep.otpVerification);
    } on BellugaAuthError catch (e) {
      generalErrorStreamValue.addValue(e.message);
    } catch (e) {
      generalErrorStreamValue.addValue(_resolveUnknownError(e));
    } finally {
      buttonLoadingValue.addValue(false);
      fieldEnabled.addValue(true);
    }
  }

  Future<void> requestPhoneOtpSmsChallenge() {
    return requestPhoneOtpChallenge(
      deliveryChannel: phoneOtpDeliveryChannelSms,
    );
  }

  Future<void> resendPhoneOtpChallenge() {
    final deliveryChannel =
        currentPhoneOtpChallengeStreamValue.value?.deliveryChannel ??
            phoneOtpDeliveryChannelWhatsapp;
    return requestPhoneOtpChallenge(deliveryChannel: deliveryChannel);
  }

  Future<void> verifyPhoneOtpChallenge() async {
    buttonLoadingValue.addValue(true);
    fieldEnabled.addValue(false);
    _cleanAllErrors();

    try {
      if (!validateOtpCodeForm()) {
        loginResultStreamValue.addValue(false);
        return;
      }

      final challenge = currentPhoneOtpChallengeStreamValue.value;
      if (challenge == null) {
        generalErrorStreamValue.addValue(
          'Solicite um novo codigo para continuar.',
        );
        loginResultStreamValue.addValue(false);
        return;
      }

      await _authRepository.verifyPhoneOtpChallenge(
        challengeId: _authTextValue(challenge.challengeId),
        phone: _authTextValue(challenge.phone),
        code: _authTextValue(otpCodeController.text.trim()),
      );
      loginResultStreamValue.addValue(_authRepository.isAuthorized);
    } on BellugaAuthError catch (e) {
      generalErrorStreamValue.addValue(e.message);
      loginResultStreamValue.addValue(false);
    } catch (e) {
      generalErrorStreamValue.addValue(_resolveUnknownError(e));
      loginResultStreamValue.addValue(false);
    } finally {
      buttonLoadingValue.addValue(false);
      fieldEnabled.addValue(true);
    }
  }

  void editPhoneNumber() {
    otpCodeController.clear();
    currentPhoneOtpChallengeStreamValue.addValue(null);
    phoneOtpStepStreamValue.addValue(AuthPhoneOtpStep.phoneEntry);
  }

  String _normalizedPhoneForOtpChallenge() {
    final phoneNumber = phoneNumberController.value;
    if (phoneNumber.nsn.trim().isNotEmpty) {
      return phoneNumber.international;
    }
    return phoneController.text.trim();
  }

  void _syncPhoneNumberController(String rawPhone) {
    try {
      phoneNumberController.value = PhoneNumber.parse(
        rawPhone,
        destinationCountry: IsoCode.BR,
      );
    } catch (_) {
      // expected_control_flow: backend may return a legacy phone shape.
    }
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
      await _authRepository.signUpWithEmailPassword(
        _authTextValue(name),
        _authTextValue(email),
        _authTextValue(password),
      );
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

  AuthRepositoryContractTextValue _authTextValue(String raw) {
    return AuthRepositoryContractTextValue.fromRaw(raw);
  }

  @override
  void onDispose() {
    authEmailFieldController.dispose();
    passwordController.dispose();
    signupNameController.dispose();
    signupEmailController.dispose();
    signupPasswordController.dispose();
    phoneController.dispose();
    otpCodeController.dispose();
    phoneNumberController.dispose();
    phoneFocusNode.dispose();
    otpCodeFocusNode.dispose();
    generalErrorStreamValue.dispose();
    buttonLoadingValue.dispose();
    fieldEnabled.dispose();
    loginResultStreamValue.dispose();
    signUpResultStreamValue.dispose();
    phoneOtpStepStreamValue.dispose();
    currentPhoneOtpChallengeStreamValue.dispose();
    sliverAppBarController.dispose();
  }
}
