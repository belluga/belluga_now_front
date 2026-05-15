import 'package:flutter/material.dart';
import 'package:belluga_form_validation/belluga_form_validation.dart';
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

final authPhoneOtpValidationConfig = FormValidationConfig(
  formId: 'auth_phone_otp',
  bindings: <FormValidationBinding>[
    fieldAny(
      const <String>[
        'code',
        'otp_code',
        'verification_code',
        'codigo',
        'código',
      ],
      targetId: AuthLoginControllerContract.phoneOtpValidationTargetCode,
    ),
    globalAny(
      const <String>[
        'global',
        'phone',
        'delivery_channel',
        'challenge',
        'challenge_id',
      ],
      targetId: AuthLoginControllerContract.phoneOtpValidationTargetGlobal,
    ),
  ],
);

abstract class AuthLoginControllerContract extends Object with Disposable {
  static const phoneOtpDeliveryChannelWhatsapp = 'whatsapp';
  static const phoneOtpDeliveryChannelSms = 'sms';
  static const phoneOtpValidationTargetGlobal = 'global';
  static const phoneOtpValidationTargetCode = 'code';

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
  final TextEditingController phoneNationalNumberTextController =
      TextEditingController();
  final TextEditingController otpCodeController = TextEditingController();
  final PhoneController phoneNumberController = PhoneController(
    initialValue: const PhoneNumber(isoCode: IsoCode.BR, nsn: ''),
  );
  final FocusNode phoneFocusNode = FocusNode();
  final FocusNode otpCodeFocusNode = FocusNode();

  final generalErrorStreamValue = StreamValue<String?>();
  final FormValidationControllerAdapter phoneOtpValidationController =
      FormValidationControllerAdapter(config: authPhoneOtpValidationConfig);
  bool _phoneOtpAutoVerificationAttempted = false;

  StreamValue<FormValidationState> get phoneOtpValidationStreamValue =>
      phoneOtpValidationController.stateStreamValue;

  void beginPhoneOtpPageSession() {
    _phoneOtpAutoVerificationAttempted = false;
  }

  void cleanEmailError(Object? _) => authEmailFieldController.cleanError();
  void cleanPasswordError(Object? _) => passwordController.cleanError();

  void _cleanAllErrors() {
    cleanEmailError(null);
    cleanPasswordError(null);
    generalErrorStreamValue.addValue(null);
    phoneOtpValidationController.clearAll();
  }

  void clearGeneralError() {
    generalErrorStreamValue.addValue(null);
    phoneOtpValidationController.clearGlobal(phoneOtpValidationTargetGlobal);
  }

  void clearPhoneOtpCodeError() {
    phoneOtpValidationController.clearField(phoneOtpValidationTargetCode);
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
      return 'Informe o código de 6 dígitos.';
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
    phoneNumberController.value = phoneNumber;
    phoneController.text = phoneNumber.international;
    _syncPhoneNationalNumberText(phoneNumber);
  }

  void updatePhoneOtpCountry(IsoCode isoCode) {
    final phoneNumber = parsePhoneNationalInputForCountry(
      phoneNationalNumberTextController.text,
      isoCode,
    );
    updatePhoneOtpInput(phoneNumber);
  }

  void updatePhoneOtpNationalInput(String rawText) {
    final trimmed = rawText.trim();
    final phoneNumber = trimmed.startsWith('+')
        ? _parseInternationalPhoneInput(trimmed)
        : parsePhoneNationalInputForCountry(
            rawText,
            phoneNumberController.value.isoCode,
          );
    updatePhoneOtpInput(phoneNumber);
  }

  String? validatePhoneNationalInput(String? raw) {
    final digits = _digitsOnly(raw ?? phoneNationalNumberTextController.text);
    if (digits.isEmpty) {
      return 'Informe seu telefone.';
    }
    return validatePhoneNumberValue(phoneNumberController.value);
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
        _applyPhoneOtpGlobalError(
          'SMS indisponível para este ambiente.',
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
      _phoneOtpAutoVerificationAttempted = false;
      currentPhoneOtpChallengeStreamValue.addValue(challenge);
      phoneController.text = challenge.phone;
      _syncPhoneNumberController(challenge.phone);
      otpCodeController.clear();
      phoneOtpStepStreamValue.addValue(AuthPhoneOtpStep.otpVerification);
    } on FormValidationFailure catch (e) {
      _applyPhoneOtpGlobalError(_resolveOtpRequestError(e));
    } on BellugaAuthError catch (e) {
      _applyPhoneOtpGlobalError(_resolveOtpRequestError(e));
    } catch (e) {
      _applyPhoneOtpGlobalError(_resolveOtpRequestError(e));
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
    if (buttonLoadingValue.value || !fieldEnabled.value) {
      return;
    }

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
        _applyPhoneOtpGlobalError(
          'Solicite um novo código para continuar.',
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
    } on FormValidationFailure catch (e) {
      _applyPhoneOtpVerificationFailure(e);
      loginResultStreamValue.addValue(false);
    } on BellugaAuthError catch (e) {
      _applyPhoneOtpVerificationFailure(e);
      loginResultStreamValue.addValue(false);
    } catch (e) {
      _applyPhoneOtpVerificationFailure(e);
      loginResultStreamValue.addValue(false);
    } finally {
      buttonLoadingValue.addValue(false);
      fieldEnabled.addValue(true);
    }
  }

  Future<void> verifyPhoneOtpChallengeOnceOnCodeComplete() async {
    if (_phoneOtpAutoVerificationAttempted) {
      return;
    }
    if (validateOtpCode(otpCodeController.text) != null) {
      return;
    }

    _phoneOtpAutoVerificationAttempted = true;
    await verifyPhoneOtpChallenge();
  }

  void editPhoneNumber() {
    _phoneOtpAutoVerificationAttempted = false;
    otpCodeController.clear();
    phoneOtpValidationController.clearAll();
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
      updatePhoneOtpInput(PhoneNumber.parse(
        rawPhone,
        destinationCountry: IsoCode.BR,
      ));
    } catch (_) {
      // expected_control_flow: backend may return a legacy phone shape.
    }
  }

  static PhoneNumber parsePhoneNationalInputForCountry(
    String raw,
    IsoCode isoCode,
  ) {
    final digits = _digitsOnly(raw);
    if (digits.isEmpty) {
      return PhoneNumber(isoCode: isoCode, nsn: '');
    }
    try {
      return PhoneNumber.parse(digits, destinationCountry: isoCode);
    } catch (_) {
      return PhoneNumber(isoCode: isoCode, nsn: digits);
    }
  }

  static String formatPhoneNationalNumberForInput(PhoneNumber phoneNumber) {
    return formatPhoneNationalDigitsForInput(
      phoneNumber.isoCode,
      phoneNumber.nsn,
    );
  }

  static String formatPhoneNationalDigitsForInput(
    IsoCode isoCode,
    String rawDigits,
  ) {
    final digits = _digitsOnly(rawDigits);
    if (digits.isEmpty) {
      return '';
    }
    if (isoCode == IsoCode.BR) {
      return _formatBrazilPhoneDigits(digits);
    }
    if ((PhoneNumber(isoCode: isoCode, nsn: '')).countryCode == '1') {
      return _formatNanpPhoneDigits(digits);
    }
    try {
      return PhoneNumber(isoCode: isoCode, nsn: digits).formatNsn();
    } catch (_) {
      return digits;
    }
  }

  static String _formatBrazilPhoneDigits(String rawDigits) {
    final digits = _digitsOnly(rawDigits);
    if (digits.length <= 1) {
      return '($digits';
    }

    final areaCode = digits.substring(0, 2);
    final localNumber = digits.substring(2);
    if (localNumber.isEmpty) {
      return '($areaCode)';
    }

    final isMobile = localNumber.startsWith('9');
    final prefixLength = isMobile ? 5 : 4;
    if (localNumber.length <= prefixLength) {
      return '($areaCode) $localNumber';
    }

    final prefix = localNumber.substring(0, prefixLength);
    final suffix = localNumber.substring(prefixLength);
    return '($areaCode) $prefix-$suffix';
  }

  static String _formatNanpPhoneDigits(String rawDigits) {
    final digits = _digitsOnly(rawDigits);
    if (digits.length <= 3) {
      return '($digits';
    }

    final areaCode = digits.substring(0, 3);
    final remainder = digits.substring(3);
    if (remainder.length <= 3) {
      return '($areaCode) $remainder';
    }

    final prefix = remainder.substring(0, 3);
    final suffix = remainder.substring(3);
    return '($areaCode) $prefix-$suffix';
  }

  static String _digitsOnly(String raw) {
    return raw.replaceAll(RegExp(r'\D+'), '');
  }

  PhoneNumber _parseInternationalPhoneInput(String raw) {
    try {
      return PhoneNumber.parse(raw);
    } catch (_) {
      return parsePhoneNationalInputForCountry(
        raw,
        phoneNumberController.value.isoCode,
      );
    }
  }

  void _syncPhoneNationalNumberText(PhoneNumber phoneNumber) {
    final formatted = formatPhoneNationalNumberForInput(phoneNumber);
    if (phoneNationalNumberTextController.text == formatted) {
      return;
    }
    phoneNationalNumberTextController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
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

  void _applyPhoneOtpCodeError(String message) {
    phoneOtpValidationController.replaceWithResolved(
      fieldErrors: <String, List<String>>{
        phoneOtpValidationTargetCode: <String>[message],
      },
    );
  }

  void _applyPhoneOtpGlobalError(String message) {
    phoneOtpValidationController.replaceWithResolved(
      globalErrors: <String, List<String>>{
        phoneOtpValidationTargetGlobal: <String>[message],
      },
    );
  }

  void _applyPhoneOtpVerificationFailure(Object error) {
    final globalError = _resolveOtpVerificationGlobalError(error);
    if (globalError != null) {
      _applyPhoneOtpGlobalError(globalError);
      return;
    }
    if (_isOtpCodeVerificationError(error)) {
      _applyPhoneOtpCodeError(_resolveOtpCodeError(error));
      return;
    }
    _applyPhoneOtpGlobalError(
      'Não conseguimos confirmar o código agora. Tente novamente em instantes.',
    );
  }

  String _resolveOtpRequestError(Object error) {
    final normalized = error.toString().toLowerCase();
    if (normalized.contains('sms') && normalized.contains('indispon')) {
      return 'SMS indisponível para este ambiente.';
    }
    if (normalized.contains('429') ||
        normalized.contains('too many') ||
        normalized.contains('rate') ||
        normalized.contains('cooldown') ||
        normalized.contains('retry_after')) {
      return 'Aguarde alguns instantes antes de pedir um novo código.';
    }
    return 'Não conseguimos enviar o código agora. Tente novamente em instantes.';
  }

  String _resolveOtpCodeError(Object error) {
    final normalized = error.toString().toLowerCase();
    if (normalized.contains('expir')) {
      return 'Código expirado. Solicite um novo código para continuar.';
    }
    if (normalized.contains('no longer active') ||
        normalized.contains('inactive') ||
        normalized.contains('challenge could not be verified')) {
      return 'Esse código não está mais válido. Solicite um novo código para continuar.';
    }
    if (normalized.contains('attempt') ||
        normalized.contains('tentativa') ||
        normalized.contains('too many')) {
      return 'Muitas tentativas. Solicite um novo código para continuar.';
    }
    return 'Código incorreto';
  }

  String? _resolveOtpVerificationGlobalError(Object error) {
    final normalized = error.toString().toLowerCase();

    if (normalized.contains('[409]') ||
        normalized.contains('statuscode: 409') ||
        normalized.contains('concurrency conflict')) {
      return 'Seu acesso está sendo consolidado. Tente novamente em instantes.';
    }

    if (normalized.contains('cannot be used to authenticate') ||
        normalized.contains('"phone"') ||
        normalized.contains("'phone'")) {
      return 'Esse telefone não pode autenticar agora.';
    }

    if (normalized.contains('challenge_id') ||
        normalized.contains('challenge could not be verified')) {
      return 'Esse código não está mais válido. Solicite um novo código para continuar.';
    }

    return null;
  }

  bool _isOtpCodeVerificationError(Object error) {
    if (error is FormValidationFailure) {
      if (error.fieldErrors.keys.any(_isPhoneOtpGlobalValidationKey)) {
        return false;
      }
      if (error.statusCode == 422) {
        return true;
      }
      return error.fieldErrors.keys.any(_isOtpCodeValidationKey);
    }

    final normalized = error.toString().toLowerCase();
    return normalized.contains('[422]') ||
        normalized.contains('statuscode: 422') ||
        normalized.contains('validation') ||
        normalized.contains('invalid') ||
        normalized.contains('expir') ||
        normalized.contains('"code"') ||
        normalized.contains("'code'") ||
        normalized.contains('codigo') ||
        normalized.contains('código');
  }

  bool _isPhoneOtpGlobalValidationKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized == 'global' ||
        normalized == 'phone' ||
        normalized == 'delivery_channel' ||
        normalized == 'challenge' ||
        normalized == 'challenge_id';
  }

  bool _isOtpCodeValidationKey(String raw) {
    final normalized = raw.trim().toLowerCase();
    return normalized == 'code' ||
        normalized == 'otp_code' ||
        normalized == 'verification_code' ||
        normalized == 'codigo' ||
        normalized == 'código';
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
    phoneNationalNumberTextController.dispose();
    otpCodeController.dispose();
    phoneNumberController.dispose();
    phoneFocusNode.dispose();
    otpCodeFocusNode.dispose();
    generalErrorStreamValue.dispose();
    phoneOtpValidationController.dispose();
    buttonLoadingValue.dispose();
    fieldEnabled.dispose();
    loginResultStreamValue.dispose();
    signUpResultStreamValue.dispose();
    phoneOtpStepStreamValue.dispose();
    currentPhoneOtpChallengeStreamValue.dispose();
    sliverAppBarController.dispose();
  }
}
