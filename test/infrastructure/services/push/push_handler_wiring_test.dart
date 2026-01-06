// ignore_for_file: must_be_immutable

import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/platform_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/venue_event/venue_event_preview_dto.dart';
import 'package:belluga_now/infrastructure/services/push/push_transport_configurator.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:push_handler/push_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildTestAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('PushTransportConfigurator builds expected config', () async {
    final authRepository =
        _FakeAuthRepository(userTokenValue: 'token-123', deviceId: 'device-1');

    final config =
        PushTransportConfigurator.build(authRepository: authRepository);

    expect(config.baseUrl, BellugaConstants.api.baseUrl);
    expect(await config.tokenProvider?.call(), 'token-123');
    expect(await config.deviceIdProvider?.call(), 'device-1');
    expect(config.enableDebugLogs, kDebugMode);
  });

  test('PushTransportConfigurator returns null token when empty', () async {
    final authRepository =
        _FakeAuthRepository(userTokenValue: '', deviceId: 'device-1');

    final config =
        PushTransportConfigurator.build(authRepository: authRepository);

    expect(await config.tokenProvider?.call(), isNull);
  });

  test('ApplicationContract initializes push repository on non-web path',
      () async {
    final authRepository =
        _FakeAuthRepository(userTokenValue: 'token-123', deviceId: 'device-1');
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

    final app = _TestApplication();
    GetIt.I.registerSingleton<ApplicationContract>(app);

    final capture = _RepositoryCapture();
    await app.initializePushHandlerForTesting(
      isWebOverride: false,
      repositoryFactory: capture.factory,
    );

    expect(capture.factoryCalled, isTrue);
    expect(capture.initCalled, isTrue);
    expect(await capture.transportConfig?.tokenProvider?.call(), 'token-123');
    expect(capture.platformResolver?.call(),
        BellugaConstants.settings.platform);
  });

  test('ApplicationContract skips push init on web override', () async {
    final authRepository =
        _FakeAuthRepository(userTokenValue: 'token-123', deviceId: 'device-1');
    GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

    final app = _TestApplication();
    GetIt.I.registerSingleton<ApplicationContract>(app);

    final capture = _RepositoryCapture();
    await app.initializePushHandlerForTesting(
      isWebOverride: true,
      repositoryFactory: capture.factory,
    );

    expect(capture.factoryCalled, isFalse);
    expect(capture.initCalled, isFalse);
  });
}

class _TestApplication extends ApplicationContract {
  _TestApplication();

  @override
  Future<void> initialSettingsPlatform() async {}
}

class _RepositoryCapture {
  bool factoryCalled = false;
  bool initCalled = false;
  PushTransportConfig? transportConfig;
  String Function()? platformResolver;

  PushHandlerRepositoryContract factory({
    required PushTransportConfig transportConfig,
    required BuildContext? Function() contextProvider,
    required PushNavigationResolver navigationResolver,
    required Future<void> Function(RemoteMessage) onBackgroundMessage,
    required Stream<dynamic>? authChangeStream,
    required String Function() platformResolver,
  }) {
    factoryCalled = true;
    this.transportConfig = transportConfig;
    this.platformResolver = platformResolver;
    return _FakePushHandlerRepository(
      transportConfig: transportConfig,
      contextProvider: contextProvider,
      navigationResolver: navigationResolver,
      onBackgroundMessage: onBackgroundMessage,
      authChangeStream: authChangeStream,
      platformResolver: platformResolver,
      onInit: () => initCalled = true,
    );
  }
}

class _FakePushHandlerRepository extends PushHandlerRepositoryContract {
  _FakePushHandlerRepository({
    required super.transportConfig,
    required super.contextProvider,
    required super.navigationResolver,
    required super.onBackgroundMessage,
    required super.authChangeStream,
    required super.platformResolver,
    required this.onInit,
  });

  final VoidCallback onInit;

  @override
  Future<void> init() async {
    onInit();
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    required this.userTokenValue,
    required this.deviceId,
  });

  final String userTokenValue;
  final String deviceId;
  final _backend = _NoopBackend();

  @override
  BackendContract get backend => _backend;

  @override
  String get userToken => userTokenValue;

  @override
  void setUserToken(String? token) {}

  @override
  Future<String> getDeviceId() async => deviceId;

  @override
  bool get isUserLoggedIn => userTokenValue.isNotEmpty;

  @override
  bool get isAuthorized => userTokenValue.isNotEmpty;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() => throw UnimplementedError();

  @override
  Future<void> loginWithEmailPassword(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> signUpWithEmailPassword(String email, String password) =>
      throw UnimplementedError();

  @override
  Future<void> sendTokenRecoveryPassword(String email, String codigoEnviado) =>
      throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<void> createNewPassword(String newPassword, String confirmPassword) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<void> updateUser(Map<String, Object?> data) =>
      throw UnimplementedError();
}

class _NoopBackend extends BackendContract {
  @override
  AuthBackendContract get auth => _NoopAuthBackend();

  @override
  TenantBackendContract get tenant => _NoopTenantBackend();

  @override
  FavoriteBackendContract get favorites => _NoopFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _NoopVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _NoopScheduleBackend();
}

class _NoopAuthBackend extends AuthBackendContract {
  @override
  Future<String> issueAnonymousIdentity({
    required String deviceName,
    required String fingerprintHash,
    String? userAgent,
    String? locale,
    Map<String, dynamic>? metadata,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<(UserDto, String)> loginWithEmailPassword(
    String email,
    String password,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<UserDto> loginCheck() => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();
}

class _NoopTenantBackend extends TenantBackendContract {
  @override
  Future<Tenant> getTenant() => throw UnimplementedError();
}

class _NoopFavoriteBackend extends FavoriteBackendContract {
  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() =>
      throw UnimplementedError();
}

class _NoopVenueEventBackend extends VenueEventBackendContract {
  @override
  Future<List<VenueEventPreviewDTO>> fetchFeaturedEvents() =>
      throw UnimplementedError();

  @override
  Future<List<VenueEventPreviewDTO>> fetchUpcomingEvents() =>
      throw UnimplementedError();
}

class _NoopScheduleBackend extends ScheduleBackendContract {
  @override
  Future<EventSummaryDTO> fetchSummary() => throw UnimplementedError();

  @override
  Future<List<EventDTO>> fetchEvents() => throw UnimplementedError();

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    required int pageSize,
    required bool showPastOnly,
    String? searchQuery,
  }) =>
      throw UnimplementedError();
}

AppData _buildTestAppData() {
  final platformType = PlatformTypeValue()..parse(PlatformType.mobile.name);
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
      'telemetry': [],
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
