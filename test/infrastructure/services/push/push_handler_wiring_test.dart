// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/application_contract.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/observability/sentry_error_reporter.dart';
import 'package:belluga_now/application/push/invite_push_runtime_coordinator.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/auth/account_deletion_journey_state.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/platform_type.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_bool_value.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/tenant/tenant.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/app_data_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_delta_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/schedule/event_page_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/venue_event/venue_event_preview_dto.dart';
import 'package:belluga_now/infrastructure/services/push/invite_push_tap_source.dart';
import 'package:belluga_now/presentation/shared/push/controllers/push_options_resolver.dart';
import 'package:belluga_now/infrastructure/services/push/push_transport_configurator.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';
import 'package:push_handler/push_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    final appData = _buildTestAppData();
    GetIt.I.registerSingleton<AppData>(appData);
    final backend = _NoopBackend();
    backend.setContext(BackendContext.fromAppData(appData));
    GetIt.I.registerSingleton<BackendContract>(backend);
    GetIt.I.registerSingleton<TelemetryRepositoryContract>(
      _FakeTelemetryRepository(),
    );
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      _FakeUserLocationRepository(),
    );
    GetIt.I.registerSingleton<ContactsRepositoryContract>(
      _FakeContactsRepository(),
    );
    GetIt.I.registerSingleton<PushOptionsResolver>(PushOptionsResolver());
  });

  tearDown(() async {
    SentryErrorReporter.resetForTesting();
    if (GetIt.I.isRegistered<ApplicationContract>()) {
      await GetIt.I.get<ApplicationContract>().disposeRuntimeResources();
    }
    await GetIt.I.reset();
  });

  test('PushTransportConfigurator builds expected config', () async {
    final authRepository = _FakeAuthRepository(
      userTokenValue: 'token-123',
      deviceId: 'device-1',
    );

    final config = PushTransportConfigurator.build(
      authRepository: authRepository,
    );

    final baseUrl = BellugaConstants.api.baseUrl;
    final expectedBaseUrl = baseUrl.endsWith('/')
        ? '${baseUrl}v1/'
        : '$baseUrl/v1/';
    expect(config.resolvedBaseUrl, expectedBaseUrl);
    expect(await config.tokenProvider?.call(), 'token-123');
    expect(await config.deviceIdProvider?.call(), 'device-1');
    expect(config.enableDebugLogs, kDebugMode);
  });

  test('PushTransportConfigurator returns null token when empty', () async {
    final authRepository = _FakeAuthRepository(
      userTokenValue: '',
      deviceId: 'device-1',
    );

    final config = PushTransportConfigurator.build(
      authRepository: authRepository,
    );

    expect(await config.tokenProvider?.call(), isNull);
  });

  test(
    'PushTransportConfigurator blocks token reuse during deletion resolution',
    () async {
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'registered-token',
        deviceId: 'device-1',
      );
      authRepository.accountDeletionJourneyStreamValue.addValue(
        const AccountDeletionJourneyState(AccountDeletionJourneyPhase.unknown),
      );

      final config = PushTransportConfigurator.build(
        authRepository: authRepository,
      );

      expect(await config.tokenProvider?.call(), isNull);
    },
  );

  test(
    'BackendContext uses canonical main domain instead of current href',
    () async {
      final appData = _buildTestAppData(
        platform: PlatformType.web,
        mainDomain: 'https://guarappari.belluga.space',
        domains: ['https://guarappari.belluga.space'],
        localHostname: 'belluga.space',
        localHref: 'https://belluga.space/admin',
      );

      final context = BackendContext.fromAppData(appData);

      expect(context.baseUrl, 'https://guarappari.belluga.space/api');
      expect(context.adminUrl, 'https://guarappari.belluga.space/admin/api');
    },
  );

  test(
    'ApplicationContract initializes push repository on non-web path',
    () async {
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'token-123',
        deviceId: 'device-1',
      );
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
      expect(
        capture.platformResolver?.call(),
        BellugaConstants.settings.platform,
      );
    },
  );

  test('ApplicationContract skips push init on web override', () async {
    final authRepository = _FakeAuthRepository(
      userTokenValue: 'token-123',
      deviceId: 'device-1',
    );
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

  test(
    'ApplicationContract skips mobile push wiring when Firebase settings are missing',
    () async {
      final appData = _buildTestAppData();
      GetIt.I.registerSingleton<AppDataRepositoryContract>(
        _FakeAppDataRepository(appData),
      );
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'token-123',
        deviceId: 'device-1',
      );
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final app = _TestApplication();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      final capture = _RepositoryCapture();
      await app.initializePushHandlerForTesting(
        isWebOverride: false,
        repositoryFactory: capture.factory,
        invitePushTapSourceOverride: _ThrowingInvitePushTapSource(),
      );

      expect(capture.factoryCalled, isFalse);
      expect(capture.initCalled, isFalse);
    },
  );

  test(
    'ApplicationContract skips iOS push wiring when only legacy Android appId is available',
    () async {
      final appData = _buildTestAppData(
        firebase: {
          'apiKey': 'firebase-key',
          'appId': '1:249193301334:android:f73db77742a1b07f2302f7',
          'projectId': 'guarappari',
          'messagingSenderId': '249193301334',
          'storageBucket': 'guarappari.firebasestorage.app',
        },
      );
      GetIt.I.registerSingleton<AppDataRepositoryContract>(
        _FakeAppDataRepository(appData),
      );
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'token-123',
        deviceId: 'device-1',
      );
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final app = _TestApplication();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      final capture = _RepositoryCapture();
      await app.initializePushHandlerForTesting(
        isWebOverride: false,
        platformOverride: 'ios',
        repositoryFactory: capture.factory,
        invitePushTapSourceOverride: _ThrowingInvitePushTapSource(),
      );

      expect(capture.factoryCalled, isFalse);
      expect(capture.initCalled, isFalse);
    },
  );

  test(
    'ApplicationContract builds iOS Firebase options from iosAppId before init',
    () async {
      final appData = _buildTestAppData(
        firebase: {
          'apiKey': 'firebase-key',
          'appId': '1:249193301334:android:f73db77742a1b07f2302f7',
          'androidAppId': '1:249193301334:android:f73db77742a1b07f2302f7',
          'iosAppId': '1:249193301334:ios:ce4aca6dbb545ca02302f7',
          'projectId': 'guarappari',
          'messagingSenderId': '249193301334',
          'storageBucket': 'guarappari.firebasestorage.app',
        },
      );
      GetIt.I.registerSingleton<AppDataRepositoryContract>(
        _FakeAppDataRepository(appData),
      );

      final app = _TestApplication();
      final options = app.firebaseOptionsForTesting(platform: 'ios');

      expect(options, isNotNull);
      expect(options!.appId, '1:249193301334:ios:ce4aca6dbb545ca02302f7');
      expect(options.projectId, 'guarappari');
    },
  );

  test(
    'ApplicationContract does not build iOS Firebase options from legacy Android appId',
    () async {
      final appData = _buildTestAppData(
        firebase: {
          'apiKey': 'firebase-key',
          'appId': '1:249193301334:android:f73db77742a1b07f2302f7',
          'projectId': 'guarappari',
          'messagingSenderId': '249193301334',
          'storageBucket': 'guarappari.firebasestorage.app',
        },
      );
      GetIt.I.registerSingleton<AppDataRepositoryContract>(
        _FakeAppDataRepository(appData),
      );

      final app = _TestApplication();
      final options = app.firebaseOptionsForTesting(platform: 'ios');

      expect(options, isNull);
    },
  );

  test(
    'ApplicationContract reports recoverable push init failures to Sentry',
    () async {
      final sentryCaptures = <_SentryCapture>[];
      SentryErrorReporter.overrideCaptureExceptionForTesting((
        throwable, {
        stackTrace,
        hint,
        message,
        withScope,
      }) async {
        sentryCaptures.add(
          _SentryCapture(
            throwable: throwable,
            stackTrace: stackTrace,
            withScope: withScope,
          ),
        );
        return SentryId.empty();
      });
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'token-123',
        deviceId: 'device-1',
      );
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final app = _TestApplication();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      final capture = _RepositoryCapture(throwOnInit: true);
      await app.initializePushHandlerForTesting(
        isWebOverride: false,
        repositoryFactory: capture.factory,
      );

      expect(capture.factoryCalled, isTrue);
      expect(capture.initCalled, isTrue);
      expect(sentryCaptures, hasLength(1));
      expect(sentryCaptures.single.throwable, isA<StateError>());
      expect(sentryCaptures.single.stackTrace, isA<StackTrace>());
    },
  );

  test(
    'ApplicationContract defers iOS push repository init until presentation ready',
    () async {
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'token-123',
        deviceId: 'device-1',
      );
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final app = _TestApplication();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      final capture = _RepositoryCapture();
      await app.initializePushHandlerForTesting(
        isWebOverride: false,
        platformOverride: 'ios',
        repositoryFactory: capture.factory,
      );

      expect(capture.factoryCalled, isFalse);
      expect(capture.initCalled, isFalse);

      await app.handlePushPresentationReady();

      expect(capture.factoryCalled, isTrue);
      expect(capture.initCalled, isTrue);
    },
  );

  test(
    'ApplicationContract waits for authorization before deferred iOS push init',
    () async {
      final authRepository = _FakeAuthRepository(
        userTokenValue: '',
        deviceId: 'device-1',
      );
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final app = _TestApplication();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      final capture = _RepositoryCapture();
      await app.initializePushHandlerForTesting(
        isWebOverride: false,
        platformOverride: 'ios',
        repositoryFactory: capture.factory,
      );
      await app.handlePushPresentationReady();

      expect(capture.factoryCalled, isFalse);
      expect(capture.initCalled, isFalse);

      authRepository.authorize(userToken: 'token-123');
      await _flushAsyncWork();

      expect(capture.factoryCalled, isTrue);
      expect(capture.initCalled, isTrue);
    },
  );

  testWidgets(
    'ApplicationContract seeds startup override from initial invite push tap',
    (tester) async {
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'token-123',
        deviceId: 'device-1',
      );
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final app = _TestApplication();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      final capture = _RepositoryCapture();
      final runtimeCoordinator = _FakeInvitePushRuntimeCoordinator(
        preparedPath: '/invite?code=ABCD1234',
      );
      await app.initializePushHandlerForTesting(
        isWebOverride: false,
        repositoryFactory: capture.factory,
        invitePushTapSourceOverride: _FakeInvitePushTapSource(
          initialMessage: RemoteMessage.fromMap(const <String, dynamic>{
            'messageId': 'push-message-1',
            'data': <String, dynamic>{
              'push_type': 'invite_received',
              'invite_id': '507f1f77bcf86cd799439011',
            },
          }),
        ),
        invitePushRuntimeCoordinatorOverride: runtimeCoordinator,
      );

      await tester.pump();

      final router = _buildStartupTestRouter();
      final delegate = router.delegate(
        deepLinkBuilder:
            app.startupNavigationCoordinatorForTesting.resolvePlatformDeepLink,
      );
      await delegate.setInitialRoutePath(
        await _parseStartupTestRoute(router, '/'),
      );

      expect(runtimeCoordinator.prepareNotificationTapPathCalls, 1);
      expect(runtimeCoordinator.refreshNotificationTapDataCalls, 1);
      expect(router.currentPath, '/invite');
      expect(router.currentUrl, '/invite?code=ABCD1234');
    },
  );

  test(
    'ApplicationContract handles iOS initial invite tap before deferred push init runs',
    () async {
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'token-123',
        deviceId: 'device-1',
      );
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final app = _TestApplication();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      final capture = _RepositoryCapture();
      final runtimeCoordinator = _FakeInvitePushRuntimeCoordinator(
        preparedPath: '/invite?code=ABCD1234',
      );
      await app.initializePushHandlerForTesting(
        isWebOverride: false,
        platformOverride: 'ios',
        repositoryFactory: capture.factory,
        invitePushTapSourceOverride: _FakeInvitePushTapSource(
          initialMessage: RemoteMessage.fromMap(const <String, dynamic>{
            'messageId': 'push-message-1',
            'data': <String, dynamic>{
              'push_type': 'invite_received',
              'invite_id': '507f1f77bcf86cd799439011',
            },
          }),
        ),
        invitePushRuntimeCoordinatorOverride: runtimeCoordinator,
      );

      expect(capture.initCalled, isFalse);
      expect(runtimeCoordinator.prepareNotificationTapPathCalls, 1);
      expect(runtimeCoordinator.refreshNotificationTapDataCalls, 1);

      await app.handlePushPresentationReady();

      expect(capture.initCalled, isTrue);
    },
  );

  testWidgets(
    'ApplicationContract seeds startup override before push repository init completes',
    (tester) async {
      final authRepository = _FakeAuthRepository(
        userTokenValue: 'token-123',
        deviceId: 'device-1',
      );
      GetIt.I.registerSingleton<AuthRepositoryContract>(authRepository);

      final app = _TestApplication();
      GetIt.I.registerSingleton<ApplicationContract>(app);

      final initCompleter = Completer<void>();
      final capture = _RepositoryCapture(initCompleter: initCompleter);
      final runtimeCoordinator = _FakeInvitePushRuntimeCoordinator(
        preparedPath: '/invite?code=ABCD1234',
      );

      final initialization = app.initializePushHandlerForTesting(
        isWebOverride: false,
        repositoryFactory: capture.factory,
        invitePushTapSourceOverride: _FakeInvitePushTapSource(
          initialMessage: RemoteMessage.fromMap(const <String, dynamic>{
            'messageId': 'push-message-1',
            'data': <String, dynamic>{
              'push_type': 'invite_received',
              'invite_id': '507f1f77bcf86cd799439011',
            },
          }),
        ),
        invitePushRuntimeCoordinatorOverride: runtimeCoordinator,
      );

      await tester.pump();

      expect(capture.initCalled, isTrue);
      expect(runtimeCoordinator.prepareNotificationTapPathCalls, 1);
      expect(runtimeCoordinator.refreshNotificationTapDataCalls, 1);

      final router = _buildStartupTestRouter();
      final delegate = router.delegate(
        deepLinkBuilder:
            app.startupNavigationCoordinatorForTesting.resolvePlatformDeepLink,
      );
      await delegate.setInitialRoutePath(
        await _parseStartupTestRoute(router, '/'),
      );

      expect(router.currentPath, '/invite');
      expect(router.currentUrl, '/invite?code=ABCD1234');

      initCompleter.complete();
      await initialization;
    },
  );
}

class _TestApplication extends ApplicationContract {
  _TestApplication();

  @override
  Future<void> initialSettingsPlatform() async {}
}

class _FakeInvitePushTapSource extends InvitePushTapSource {
  const _FakeInvitePushTapSource({this.initialMessage});

  final RemoteMessage? initialMessage;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      const Stream<RemoteMessage>.empty();
}

class _ThrowingInvitePushTapSource extends InvitePushTapSource {
  @override
  Future<RemoteMessage?> getInitialMessage() {
    throw StateError('Firebase tap source should not be touched.');
  }

  @override
  Stream<RemoteMessage> get onMessageOpenedApp {
    throw StateError('Firebase tap stream should not be touched.');
  }
}

class _FakeInvitePushRuntimeCoordinator extends InvitePushRuntimeCoordinator {
  _FakeInvitePushRuntimeCoordinator({required this.preparedPath})
    : super(navigatePath: (_) async {});

  final String preparedPath;
  int prepareNotificationTapPathCalls = 0;
  int refreshNotificationTapDataCalls = 0;

  @override
  String? prepareNotificationTapPath(RemoteMessage message) {
    prepareNotificationTapPathCalls += 1;
    return preparedPath;
  }

  @override
  Future<void> refreshNotificationTapData(RemoteMessage message) async {
    refreshNotificationTapDataCalls += 1;
  }
}

class _RepositoryCapture {
  _RepositoryCapture({this.throwOnInit = false, this.initCompleter});

  final bool throwOnInit;
  final Completer<void>? initCompleter;
  bool factoryCalled = false;
  bool initCalled = false;
  PushTransportConfig? transportConfig;
  String Function()? platformResolver;

  PushHandlerRepositoryContract factory({
    required PushTransportConfig transportConfig,
    required BuildContext? Function() contextProvider,
    required PushNavigationResolver navigationResolver,
    required Future<void> Function(RemoteMessage) onBackgroundMessage,
    Future<void> Function()? presentationGate,
    required Stream<dynamic>? authChangeStream,
    required String Function() platformResolver,
    PushMessagePresenter? presenterOverride,
    Future<bool> Function(StepData step)? gatekeeper,
    Future<List<OptionItem>> Function(OptionSource source)? optionsBuilder,
    Future<void> Function(AnswerPayload answer, StepData step)? onStepSubmit,
    String? Function(StepData step, String? value)? stepValidator,
    Future<void> Function(ButtonData button, StepData step)? onCustomAction,
    void Function(PushEvent event)? onPushEvent,
  }) {
    factoryCalled = true;
    this.transportConfig = transportConfig;
    this.platformResolver = platformResolver;
    return _FakePushHandlerRepository(
      transportConfig: transportConfig,
      contextProvider: contextProvider,
      navigationResolver: navigationResolver,
      onBackgroundMessage: onBackgroundMessage,
      presentationGate: presentationGate,
      authChangeStream: authChangeStream,
      platformResolver: platformResolver,
      presenterOverride: presenterOverride,
      gatekeeper: gatekeeper,
      optionsBuilder: optionsBuilder,
      onStepSubmit: onStepSubmit,
      stepValidator: stepValidator,
      onCustomAction: onCustomAction,
      onPushEvent: onPushEvent,
      onInit: () {
        initCalled = true;
        if (throwOnInit) {
          throw StateError('push init failed');
        }
      },
      initCompleter: initCompleter,
    );
  }
}

RootStackRouter _buildStartupTestRouter() {
  return RootStackRouter.build(
    routes: <AutoRoute>[
      AutoRoute(path: '/', page: TenantHomeRoute.page),
      AutoRoute(path: '/invite', page: InviteFlowRoute.page),
    ],
  );
}

Future<UrlState> _parseStartupTestRoute(RootStackRouter router, String path) {
  return router
      .defaultRouteParser(includePrefixMatches: false)
      .parseRouteInformation(RouteInformation(uri: Uri.parse(path)));
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _SentryCapture {
  _SentryCapture({
    required this.throwable,
    required this.stackTrace,
    required this.withScope,
  });

  final dynamic throwable;
  final dynamic stackTrace;
  final ScopeCallback? withScope;
}

class _FakeUser extends UserContract {
  _FakeUser({required super.uuidValue, required super.profile});
}

_FakeUser _buildUser(String id) {
  final normalized = id.padRight(24, '0').substring(0, 24);
  return _FakeUser(
    uuidValue: MongoIDValue(defaultValue: normalized)..parse(normalized),
    profile: UserProfileContract(),
  );
}

class _FakePushHandlerRepository extends PushHandlerRepositoryContract {
  _FakePushHandlerRepository({
    required super.transportConfig,
    required super.contextProvider,
    required super.navigationResolver,
    required super.onBackgroundMessage,
    super.presentationGate,
    super.gatekeeper,
    super.optionsBuilder,
    super.onStepSubmit,
    super.stepValidator,
    super.onCustomAction,
    super.presenterOverride,
    super.onPushEvent,
    required super.authChangeStream,
    required super.platformResolver,
    required this.onInit,
    this.initCompleter,
  });

  final VoidCallback onInit;
  final Completer<void>? initCompleter;

  @override
  Future<void> init() async {
    onInit();
    await initCompleter?.future;
  }
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(this._appData);

  final AppData _appData;
  final StreamValue<ThemeMode?> _themeModeStreamValue = StreamValue<ThemeMode?>(
    defaultValue: ThemeMode.light,
  );
  final StreamValue<DistanceInMetersValue> _maxRadiusMetersStreamValue =
      StreamValue<DistanceInMetersValue>(
        defaultValue: DistanceInMetersValue.fromRaw(50000, defaultValue: 50000),
      );

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  StreamValue<ThemeMode?> get themeModeStreamValue => _themeModeStreamValue;

  @override
  ThemeMode get themeMode => _themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    _themeModeStreamValue.addValue(mode.value);
  }

  @override
  StreamValue<DistanceInMetersValue> get maxRadiusMetersStreamValue =>
      _maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters =>
      _maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    _maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeUserLocationRepository implements UserLocationRepositoryContract {
  @override
  final StreamValue<CityCoordinate?> userLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<CityCoordinate?> lastKnownLocationStreamValue =
      StreamValue<CityCoordinate?>(defaultValue: null);

  @override
  final StreamValue<DateTime?> lastKnownCapturedAtStreamValue =
      StreamValue<DateTime?>(defaultValue: null);

  @override
  final StreamValue<double?> lastKnownAccuracyStreamValue =
      StreamValue<double?>(defaultValue: null);

  @override
  final StreamValue<String?> lastKnownAddressStreamValue = StreamValue<String?>(
    defaultValue: null,
  );

  @override
  final StreamValue<LocationResolutionPhase>
  locationResolutionPhaseStreamValue = StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {}

  @override
  Future<void> setLastKnownAddress(Object? address) async {
    lastKnownAddressStreamValue.addValue(address as dynamic);
  }

  @override
  Future<bool> warmUpIfPermitted() async => false;

  @override
  Future<bool> refreshIfPermitted({Object? minInterval}) async => false;

  @override
  Future<String?> resolveUserLocation({
    Object? timeout,
    UserLocationRepositoryContractBoolValue? requestPermissionIfNeededValue,
  }) async => null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async => false;

  @override
  Future<void> stopTracking() async {}
}

class _FakeContactsRepository implements ContactsRepositoryContract {
  @override
  Future<void> clearCurrentIdentityState() async {}

  @override
  final contactsStreamValue = StreamValue<List<ContactModel>?>(
    defaultValue: null,
  );

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<List<ContactModel>> getContacts() async => const [];

  @override
  Future<void> initializeContacts() async {
    await refreshContacts();
  }

  @override
  Future<void> loadCachedContacts() async {
    contactsStreamValue.addValue(await getContacts());
  }

  @override
  Future<void> refreshCachedContacts() async {
    contactsStreamValue.addValue(await getContacts());
  }

  @override
  Future<void> refreshContacts() async {
    contactsStreamValue.addValue(await getContacts());
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({required this.userTokenValue, required this.deviceId});

  String userTokenValue;
  final String deviceId;
  final _backend = _NoopBackend();

  @override
  BackendContract get backend => _backend;

  @override
  String get userToken => userTokenValue;

  void authorize({required String userToken, UserContract? user}) {
    userTokenValue = userToken;
    userStreamValue.addValue(user ?? _buildUser('507f1f77bcf86cd799439011'));
  }

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => deviceId;

  @override
  Future<String?> getUserId() async => null;

  @override
  bool get isUserLoggedIn => userTokenValue.isNotEmpty;

  @override
  bool get isAuthorized => userTokenValue.isNotEmpty;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() => throw UnimplementedError();

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) => throw UnimplementedError();

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) => throw UnimplementedError();

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) => throw UnimplementedError();

  @override
  Future<void> logout() => throw UnimplementedError();

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) => throw UnimplementedError();

  @override
  Future<void> updateUser(UserCustomData data) => throw UnimplementedError();
}

class _FakeTelemetryRepository implements TelemetryRepositoryContract {
  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    return telemetryRepoBool(true);
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    return null;
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) async {
    return telemetryRepoBool(true);
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() async {
    return telemetryRepoBool(true);
  }

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {}

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() => null;

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async {
    return telemetryRepoBool(true);
  }
}

class _NoopBackend extends BackendContract {
  BackendContext? _context;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  AppDataBackendContract get appData => _NoopAppDataBackend();

  @override
  AuthBackendContract get auth => _NoopAuthBackend();

  @override
  TenantBackendContract get tenant => _NoopTenantBackend();

  @override
  AccountProfilesBackendContract get accountProfiles =>
      _NoopAccountProfilesBackend();

  @override
  FavoriteBackendContract get favorites => _NoopFavoriteBackend();

  @override
  VenueEventBackendContract get venueEvents => _NoopVenueEventBackend();

  @override
  ScheduleBackendContract get schedule => _NoopScheduleBackend();
}

class _NoopAppDataBackend extends AppDataBackendContract {
  @override
  Future<AppDataDTO> fetch() => throw UnimplementedError();
}

class _NoopAccountProfilesBackend implements AccountProfilesBackendContract {
  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required int page,
    required int pageSize,
    String? query,
    String? typeFilter,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
    List<String>? allowedTypes,
  }) => throw UnimplementedError();

  @override
  Future<AccountProfileModel?> fetchAccountProfileBySlug(String slug) =>
      throw UnimplementedError();

  @override
  Future<List<AccountProfileModel>> fetchNearbyAccountProfiles({
    int pageSize = 10,
    List<String>? typeFilters,
    List<dynamic>? taxonomyFilters,
  }) => throw UnimplementedError();
}

class _NoopAuthBackend extends AuthBackendContract {
  @override
  Future<AnonymousIdentityResponse> issueAnonymousIdentity({
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

  @override
  Future<AuthRegistrationResponse> registerWithEmailPassword({
    required String name,
    required String email,
    required String password,
    List<String>? anonymousUserIds,
  }) => throw UnimplementedError();
}

class _NoopTenantBackend extends TenantBackendContract {
  @override
  Future<Tenant> getTenant() => throw UnimplementedError();
}

class _NoopFavoriteBackend extends FavoriteBackendContract {
  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() =>
      throw UnimplementedError();

  @override
  Future<void> favoriteAccountProfile(String accountProfileId) =>
      throw UnimplementedError();

  @override
  Future<void> unfavoriteAccountProfile(String accountProfileId) =>
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
  Future<EventDTO?> fetchEventDetail({
    required String eventIdOrSlug,
    String? occurrenceId,
  }) => throw UnimplementedError();

  @override
  Future<EventPageDTO> fetchEventsPage({
    required int page,
    int? pageSize,
    required bool showPastOnly,
    bool liveNowOnly = false,
    String? searchQuery,
    List<String>? categories,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    List<String>? occurrenceIds,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
  }) => throw UnimplementedError();

  @override
  Stream<EventDeltaDTO> watchEventsStream({
    String? searchQuery,
    List<String>? categories,
    List<Map<String, String>>? taxonomy,
    bool confirmedOnly = false,
    List<String>? occurrenceIds,
    double? originLat,
    double? originLng,
    double? maxDistanceMeters,
    String? lastEventId,
    bool showPastOnly = false,
  }) => const Stream.empty();
}

AppData _buildTestAppData({
  PlatformType platform = PlatformType.mobile,
  String mainDomain = 'https://guarappari.com.br',
  List<String> domains = const ['https://guarappari.com.br'],
  String localHostname = 'guarappari.com.br',
  String localHref = 'https://guarappari.com.br',
  Map<String, Object?>? firebase,
}) {
  final platformType = PlatformTypeValue()..parse(platform.name);
  final remoteData = <String, Object?>{
    'name': 'Guarappari',
    'type': 'tenant',
    'main_domain': mainDomain,
    'domains': domains,
    'app_domains': [],
    'theme_data_settings': {
      'primary_seed_color': '#4FA0E3',
      'secondary_seed_color': '#E80D5D',
      'brightness_default': 'light',
    },
    'main_color': '#4FA0E3',
    'tenant_id': 'tenant-1',
    'telemetry': {'trackers': []},
  };
  if (firebase != null) {
    remoteData['firebase'] = firebase;
  }

  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: {
      'platformType': platformType,
      'hostname': localHostname,
      'href': localHref,
      'port': null,
      'device': 'test-device',
    },
  );
}
