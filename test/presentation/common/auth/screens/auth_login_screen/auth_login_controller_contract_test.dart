import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/auth/auth_phone_otp_challenge.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_challenge_id_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_delivery_channel_value.dart';
import 'package:belluga_now/domain/auth/value_objects/auth_phone_otp_phone_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/domain_optional_date_time_value.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/application/configurations/widget_keys.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/auth_login_controller.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/widgets/auth_login_canva_content.dart';
import 'package:belluga_now/presentation/tenant_public/auth/login/controllers/auth_login_controller_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:pinput/pinput.dart';
import 'package:stream_value/core/stream_value.dart';

class _FailingAuthRepository implements AuthRepositoryContract<UserContract> {
  _FailingAuthRepository();

  @override
  final userStreamValue = StreamValue<UserContract?>();

  @override
  UserContract get user => userStreamValue.value!;

  @override
  BackendContract get backend => _FakeBackend();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => null;

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {
    throw Exception('Falha backend');
  }

  @override
  Future<AuthPhoneOtpChallenge> requestPhoneOtpChallenge(
    AuthRepositoryContractParamString phone, {
    AuthRepositoryContractParamString? deliveryChannel,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> verifyPhoneOtpChallenge({
    required AuthRepositoryContractParamString challengeId,
    required AuthRepositoryContractParamString phone,
    required AuthRepositoryContractParamString code,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(UserCustomData data) async {
    throw UnimplementedError();
  }
}

class _FakeBackend implements BackendContract {
  BackendContext? _context;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _FailingAuthRepository(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'tryLoginWithEmailPassword surfaces unknown error message',
    (tester) async {
      final controller = AuthLoginController(
        initialEmail: 'user@example.com',
        initialPassword: 'password123',
      );
      controller.authEmailFieldController.addValue('user@example.com');
      controller.passwordController.addValue('password123');

      await tester.pumpWidget(
        MaterialApp(
          home: Form(
            key: controller.loginFormKey,
            child: const SizedBox(),
          ),
        ),
      );

      await controller.tryLoginWithEmailPassword();
      await tester.pump();

      expect(controller.generalErrorStreamValue.value, 'Falha backend');
      expect(controller.loginResultStreamValue.value, isFalse);
    },
  );

  testWidgets(
    'requestPhoneOtpChallenge advances to verification step',
    (tester) async {
      final repository = _PhoneOtpAuthRepository();
      final controller = AuthLoginController(authRepository: repository);
      const phoneNumber = PhoneNumber(isoCode: IsoCode.BR, nsn: '27999990000');
      controller.phoneNumberController.value = phoneNumber;
      controller.updatePhoneOtpInput(phoneNumber);

      await controller.requestPhoneOtpChallenge();
      await tester.pump();

      expect(repository.requestedPhones, ['+5527999990000']);
      expect(repository.requestedDeliveryChannels, ['whatsapp']);
      expect(
        controller.phoneOtpStepStreamValue.value,
        AuthPhoneOtpStep.otpVerification,
      );
      expect(
        controller.currentPhoneOtpChallengeStreamValue.value?.challengeId,
        'challenge-1',
      );
    },
  );

  testWidgets(
    'verifyPhoneOtpChallenge marks login result true after repository auth',
    (tester) async {
      final repository = _PhoneOtpAuthRepository();
      final controller = AuthLoginController(authRepository: repository);
      const phoneNumber = PhoneNumber(isoCode: IsoCode.BR, nsn: '27999990000');
      controller.phoneNumberController.value = phoneNumber;
      controller.updatePhoneOtpInput(phoneNumber);

      await controller.requestPhoneOtpChallenge();
      controller.otpCodeController.text = '123456';
      await controller.verifyPhoneOtpChallenge();
      await tester.pump();

      expect(repository.verifiedChallengeIds, ['challenge-1']);
      expect(controller.loginResultStreamValue.value, isTrue);
    },
  );

  testWidgets(
    'tenant public login surface shows phone otp instead of password signup',
    (tester) async {
      final repository = _PhoneOtpAuthRepository();
      final controller = AuthLoginController(authRepository: repository);

      await tester.pumpWidget(
        _buildLocalizedTestApp(
          home: Scaffold(
            body: AuthLoginCanvaContent(
              controller: controller,
              navigateToPasswordRecover: () async {},
            ),
          ),
        ),
      );

      expect(find.byKey(WidgetKeys.auth.loginPhoneField), findsOneWidget);
      expect(find.byKey(WidgetKeys.auth.loginPasswordField), findsNothing);
      expect(find.text('Criar conta'), findsNothing);
      expect(find.text('Esqueci minha senha.'), findsNothing);
    },
  );

  testWidgets(
    'tenant public otp form uses country-aware phone input and segmented code',
    (tester) async {
      final repository = _PhoneOtpAuthRepository();
      final controller = AuthLoginController(authRepository: repository);
      controller.phoneController.text = '+5527999990000';
      controller.currentPhoneOtpChallengeStreamValue.addValue(
        _buildOtpChallenge(
          phone: '+5527999990000',
          deliveryChannel: 'whatsapp',
        ),
      );
      controller.phoneOtpStepStreamValue.addValue(
        AuthPhoneOtpStep.otpVerification,
      );

      await tester.pumpWidget(
        _buildLocalizedTestApp(
          home: Scaffold(
            body: AuthLoginCanvaContent(
              controller: controller,
              navigateToPasswordRecover: () async {},
            ),
          ),
        ),
      );

      expect(find.byType(Pinput), findsOneWidget);
      expect(find.text('Codigo enviado por WhatsApp'), findsOneWidget);
      expect(find.text('Receber por SMS'), findsNothing);
    },
  );

  testWidgets(
    'sms fallback sends explicit sms channel only when app data exposes it',
    (tester) async {
      await GetIt.I.reset();
      GetIt.I.registerSingleton<AppData>(_buildAppData(smsFallback: true));

      final repository = _PhoneOtpAuthRepository();
      final controller = AuthLoginController(authRepository: repository);
      controller.phoneController.text = '+55 27 99999-0000';

      await controller.requestPhoneOtpChallenge();
      await controller.requestPhoneOtpSmsChallenge();
      await tester.pump();

      expect(repository.requestedDeliveryChannels, ['whatsapp', 'sms']);
      expect(
        controller.currentPhoneOtpChallengeStreamValue.value?.deliveryChannel,
        'sms',
      );
    },
  );
}

AuthPhoneOtpChallenge _buildOtpChallenge({
  required String phone,
  required String deliveryChannel,
}) {
  return AuthPhoneOtpChallenge(
    challengeIdValue: AuthPhoneOtpChallengeIdValue()..parse('challenge-1'),
    phoneValue: AuthPhoneOtpPhoneValue()..parse(phone),
    deliveryChannelValue: AuthPhoneOtpDeliveryChannelValue()
      ..parse(deliveryChannel),
    expiresAtValue: DomainOptionalDateTimeValue()..set(DateTime.utc(2026)),
    resendAvailableAtValue: DomainOptionalDateTimeValue()
      ..set(DateTime.utc(2026)),
  );
}

class _PhoneOtpAuthRepository implements AuthRepositoryContract<UserContract> {
  final requestedPhones = <String>[];
  final requestedDeliveryChannels = <String>[];
  final verifiedChallengeIds = <String>[];
  bool _authorized = false;

  @override
  final userStreamValue = StreamValue<UserContract?>();

  @override
  UserContract get user => userStreamValue.value!;

  @override
  BackendContract get backend => _FakeBackend();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => null;

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => _authorized;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<AuthPhoneOtpChallenge> requestPhoneOtpChallenge(
    AuthRepositoryContractParamString phone, {
    AuthRepositoryContractParamString? deliveryChannel,
  }) async {
    requestedPhones.add(phone.value);
    final channel = deliveryChannel?.value ?? 'whatsapp';
    requestedDeliveryChannels.add(channel);
    return _buildOtpChallenge(
      phone: phone.value,
      deliveryChannel: channel,
    );
  }

  @override
  Future<void> verifyPhoneOtpChallenge({
    required AuthRepositoryContractParamString challengeId,
    required AuthRepositoryContractParamString phone,
    required AuthRepositoryContractParamString code,
  }) async {
    verifiedChallengeIds.add(challengeId.value);
    _authorized = true;
  }

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

Widget _buildLocalizedTestApp({required Widget home}) {
  return MaterialApp(
    locale: const Locale('pt', 'BR'),
    supportedLocales: const <Locale>[Locale('pt', 'BR')],
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      ...PhoneFieldLocalization.delegates,
    ],
    home: home,
  );
}

AppData _buildAppData({bool smsFallback = false}) {
  final platformType = PlatformTypeValue()..parse(AppType.mobile.name);
  return buildAppDataFromInitialization(
    remoteData: {
      'name': 'Guarappari',
      'type': 'tenant',
      'main_domain': 'https://guarappari.com.br',
      'domains': ['https://guarappari.com.br'],
      'app_domains': [],
      'theme_data_settings': {
        'primary_seed_color': '#4FA0E3',
        'secondary_seed_color': '#E80D5D',
        'brightness_default': 'light',
      },
      'main_color': '#4FA0E3',
      'tenant_id': 'tenant-1',
      'telemetry': {'trackers': []},
      if (smsFallback)
        'settings': {
          'outbound_integrations': {
            'otp': {
              'webhook_url': 'https://example.com/sms',
            },
          },
        },
    },
    localInfo: {
      'platformType': platformType,
      'hostname': 'guarappari.com.br',
      'href': 'https://guarappari.com.br',
      'port': null,
      'device': 'test-device',
    },
  );
}
