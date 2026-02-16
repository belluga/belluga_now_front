import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/controllers/profile_screen_controller.dart';
import 'package:belluga_now/presentation/tenant/profile/screens/profile_screen/profile_screen.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/profile_avatar_storage_contract.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class _FakeBackendContract extends Fake implements BackendContract {}

class _FakeAppData extends Fake implements AppData {}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({required this.backend});

  @override
  final BackendContract backend;

  @override
  String get userToken => '';

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => 'device';

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
  Future<void> loginWithEmailPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    String name,
    String email,
    String password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    String email,
    String codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> updateUser(Map<String, Object?> data) async {}
}

class _FakeAppDataRepository implements AppDataRepositoryContract {
  _FakeAppDataRepository({
    ThemeMode? initialThemeMode,
    double initialMaxRadiusMeters = 5000,
  })  : _themeMode = initialThemeMode ?? ThemeMode.light,
        _maxRadiusMeters = initialMaxRadiusMeters,
        themeModeStreamValue =
            StreamValue<ThemeMode?>(defaultValue: initialThemeMode),
        maxRadiusMetersStreamValue =
            StreamValue<double>(defaultValue: initialMaxRadiusMeters);

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue;
  @override
  final StreamValue<double> maxRadiusMetersStreamValue;
  final AppData _appData = _FakeAppData();
  ThemeMode _themeMode;
  double _maxRadiusMeters;

  @override
  AppData get appData => _appData;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  double get maxRadiusMeters => _maxRadiusMeters;

  @override
  Future<void> init() async {}

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    themeModeStreamValue.addValue(mode);
  }

  @override
  Future<void> setMaxRadiusMeters(double meters) async {
    _maxRadiusMeters = meters;
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeProfileAvatarStorage implements ProfileAvatarStorageContract {
  String? _path;

  @override
  Future<String?> readAvatarPath() async => _path;

  @override
  Future<void> writeAvatarPath(String path) async {
    _path = path;
  }

  @override
  Future<void> clearAvatarPath() async {
    _path = null;
  }
}

class _FakeUser implements UserContract {
  _FakeUser({
    required this.uuidValue,
    required this.profile,
  });

  @override
  final MongoIDValue uuidValue;

  @override
  final UserProfileContract profile;

  @override
  Map<String, Object?>? customData;

  @override
  Future<void> updateCustomData(Map<String, Object?> newCustomData) async {
    customData = newCustomData;
  }
}

class _RecordingStackRouter extends Mock implements StackRouter {
  bool replaceAllCalled = false;
  List<PageRouteInfo>? lastRoutes;

  @override
  Future<void> replaceAll(
    List<PageRouteInfo> routes, {
    OnNavigationFailure? onFailure,
    bool updateExistingRoutes = true,
  }) async {
    replaceAllCalled = true;
    lastRoutes = routes;
  }
}

void main() {
  late _RecordingStackRouter mockRouter;

  setUp(() async {
    await GetIt.I.reset();
    mockRouter = _RecordingStackRouter();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
    'ProfileScreenController resolves with only profile dependencies',
    () {
      final authRepository =
          _FakeAuthRepository(backend: _FakeBackendContract());
      final appDataRepository = _FakeAppDataRepository();
      final avatarStorage = _FakeProfileAvatarStorage();

      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);
      GetIt.I.registerSingleton<AppDataRepositoryContract>(appDataRepository);
      GetIt.I.registerSingleton<ProfileAvatarStorageContract>(avatarStorage);

      // Guardrail: profile must resolve from repositories, never from another feature controller.
      expect(
        () => ProfileScreenController(),
        returnsNormally,
      );
    },
  );

  testWidgets('Profile stays visible in user mode (no auto-redirect)',
      (tester) async {
    final controller = _buildController();
    GetIt.I.registerSingleton<ProfileScreenController>(controller);
    await tester.pumpWidget(
      StackRouterScope(
        controller: mockRouter,
        stateHash: 0,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(mockRouter.replaceAllCalled, isFalse);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('Profile updates when user stream changes', (tester) async {
    final authRepository = _FakeAuthRepository(backend: _FakeBackendContract());
    final appDataRepository = _FakeAppDataRepository();
    final avatarStorage = _FakeProfileAvatarStorage();

    final controller = ProfileScreenController(
      authRepository: authRepository,
      appDataRepository: appDataRepository,
      avatarStorage: avatarStorage,
    );

    GetIt.I.registerSingleton<ProfileScreenController>(controller);
    await tester.pumpWidget(
      StackRouterScope(
        controller: mockRouter,
        stateHash: 0,
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Alice Smith'), findsNothing);

    final user = _FakeUser(
      uuidValue: MongoIDValue()..parse('507f1f77bcf86cd799439011'),
      profile: UserProfileContract(
        nameValue: FullNameValue()..parse('Alice Smith'),
        emailValue: EmailAddressValue()..parse('alice@example.com'),
      ),
    );
    authRepository.userStreamValue.addValue(user);
    await tester.pump();
    await tester.pump();

    expect(find.text('Alice Smith'), findsWidgets);
  });
}

ProfileScreenController _buildController() {
  final authRepository = _FakeAuthRepository(backend: _FakeBackendContract());
  final appDataRepository = _FakeAppDataRepository();
  final avatarStorage = _FakeProfileAvatarStorage();

  return ProfileScreenController(
    authRepository: authRepository,
    appDataRepository: appDataRepository,
    avatarStorage: avatarStorage,
  );
}
