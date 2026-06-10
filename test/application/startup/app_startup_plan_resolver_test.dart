import 'package:belluga_now/application/startup/app_startup_plan_resolver.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/app_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/invites/invite_runtime_settings.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_cooldowns_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_rate_limits_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'resolvePlan keeps anonymous tenant home startup on the public surface when there is no deferred or pending invite override',
      () async {
    final authRepository = _FakeAuthRepository();
    final resolver = AppStartupPlanResolver(
      authRepository: authRepository,
      invitesRepository: _FakeInvitesRepository(),
      appDataRepository: _FakeAppDataRepository(_buildTenantAppData()),
      deferredLinkRepository: null,
      telemetryRepository: null,
    );

    final plan = await resolver.resolvePlan();

    expect(plan.hasOverride, isFalse);
    expect(plan.path, isNull);
    expect(plan.routes, isEmpty);
    expect(plan.toDeepLink(), isNull);
    expect(authRepository.initCallCount, 1);
  });
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  int initCallCount = 0;

  @override
  Object get backend => Object();

  @override
  String get userToken => '';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => null;

  @override
  bool get isUserLoggedIn => false;

  @override
  bool get isAuthorized => false;

  @override
  Future<void> init() async {
    initCallCount += 1;
  }

  @override
  Future<void> autoLogin() async {}

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

class _FakeInvitesRepository extends InvitesRepositoryContract {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<InviteModel>> fetchInvites({
    InvitesRepositoryContractPrimInt? page,
    InvitesRepositoryContractPrimInt? pageSize,
  }) async {
    return const <InviteModel>[];
  }

  @override
  Future<InviteRuntimeSettings> fetchSettings() async {
    return InviteRuntimeSettings(
      limitValues: InviteRateLimitsValue(),
      cooldownValues: InviteCooldownsValue(),
    );
  }
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;
  final _themeMode = StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);
  final _maxRadius =
      StreamValue<DistanceInMetersValue>(defaultValue: DistanceInMetersValue()
        ..set(50000));

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeMode;

  @override
  ThemeMode get themeMode => _themeMode.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {}

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      _maxRadius;

  @override
  DistanceInMetersValue get maxRadiusMeters => _maxRadius.value;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    _maxRadius.addValue(meters);
  }
}

AppData _buildTenantAppData() {
  final platform = PlatformTypeValue(defaultValue: AppType.mobile)
    ..parse(AppType.mobile.name);
  return buildAppDataFromInitialization(
    remoteData: {
      'name': 'Tenant',
      'type': 'tenant',
      'main_domain': 'https://guarappari.belluga.space',
      'profile_types': const <Map<String, dynamic>>[],
      'domains': const <String>['https://guarappari.belluga.space'],
      'app_domains': const <String>[],
      'theme_data_settings': {
        'primary_seed_color': '#000000',
        'secondary_seed_color': '#FFFFFF',
        'brightness_default': 'light',
      },
    },
    localInfo: {
      'platformType': platform,
      'port': '1.0.0',
      'hostname': 'guarappari.belluga.space',
      'href': 'https://guarappari.belluga.space',
      'device': 'test-device',
    },
  );
}
