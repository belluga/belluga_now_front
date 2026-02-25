import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/presentation/shared/auth/screens/auth_login_screen/controllers/auth_login_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
  void setUserToken(String? token) {}

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
  Future<void> loginWithEmailPassword(String email, String password) async {
    throw Exception('Falha backend');
  }

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(Map<String, Object?> data) async {
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
}

AppData _buildAppData() {
  final platformType = PlatformTypeValue()..parse(AppType.mobile.name);
  return AppData.fromInitialization(
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
