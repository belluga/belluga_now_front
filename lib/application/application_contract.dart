// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:belluga_now/application/configurations/custom_scroll_behavior.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/router/app_router.dart';
import 'package:belluga_now/application/router/modular_app/module_settings.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/repositories/push/push_payload_upsert_mixin.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:push_handler/push_handler.dart';
import 'package:belluga_now/infrastructure/services/push/push_transport_configurator.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';

typedef PushHandlerRepositoryFactory = PushHandlerRepositoryContract Function({
  required PushTransportConfig transportConfig,
  required BuildContext? Function() contextProvider,
  required PushNavigationResolver navigationResolver,
  required Future<void> Function(RemoteMessage) onBackgroundMessage,
  required Stream<dynamic>? authChangeStream,
  required String Function() platformResolver,
});

abstract class ApplicationContract extends ModularAppContract {
  ApplicationContract({super.key}) : _appRouter = AppRouter();

  final AppRouter _appRouter;
  final _moduleSettings = ModuleSettings();
  StreamSubscription<RemoteMessage>? _pushMessageSubscription;

  Future<void> initialSettingsPlatform();

  @override
  AppRouter get appRouter => _appRouter;

  @override
  ModuleSettings get moduleSettings => _moduleSettings;

  Future<void> initialSettings() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting();
    await findSystemLocale();
  }

  @override
  Future<void> init() async {
    await initialSettings();
    await initialSettingsPlatform();

    // Log build info once to help verify the running version (web/mobile/desktop).
    try {
      final info = await PackageInfo.fromPlatform();
      debugPrint('[BuildInfo] ${info.appName} ${info.version}+${info.buildNumber} (${info.packageName})');
    } catch (_) {
      // Ignore if package info is unavailable for this platform.
    }

    await super.init();
    await _initializeFirebaseIfAvailable();
    await _initializePushHandler();
  }

  Future<void> _initializePushHandler() async {
    await _initializePushHandlerInternal();
  }

  @visibleForTesting
  Future<void> initializePushHandlerForTesting({
    bool? isWebOverride,
    PushHandlerRepositoryFactory? repositoryFactory,
    AuthRepositoryContract? authRepositoryOverride,
  }) async {
    await _initializePushHandlerInternal(
      isWebOverride: isWebOverride,
      repositoryFactory: repositoryFactory,
      authRepositoryOverride: authRepositoryOverride,
    );
  }

  Future<void> _initializePushHandlerInternal({
    bool? isWebOverride,
    PushHandlerRepositoryFactory? repositoryFactory,
    AuthRepositoryContract? authRepositoryOverride,
  }) async {
    final isWeb = isWebOverride ?? kIsWeb;
    if (isWeb) {
      debugPrint(
        '[Push] Web registration skipped; Firebase web config/VAPID not configured.',
      );
      return;
    }
    final authRepository =
        authRepositoryOverride ?? GetIt.I.get<AuthRepositoryContract>();
    final transportConfig =
        PushTransportConfigurator.build(authRepository: authRepository);
    final navigationResolver = moduleSettings.buildPushNavigationResolver();
    final factory = repositoryFactory ??
        ({
          required PushTransportConfig transportConfig,
          required BuildContext? Function() contextProvider,
          required PushNavigationResolver navigationResolver,
          required Future<void> Function(RemoteMessage) onBackgroundMessage,
          required Stream<dynamic>? authChangeStream,
          required String Function() platformResolver,
        }) {
          return PushHandlerRepositoryDefault(
            transportConfig: transportConfig,
            contextProvider: contextProvider,
            navigationResolver: navigationResolver,
            onBackgroundMessage: onBackgroundMessage,
            authChangeStream: authChangeStream,
            platformResolver: platformResolver,
          );
        };
    final repository = factory(
      transportConfig: transportConfig,
      contextProvider: () => appRouter.navigatorKey.currentContext,
      navigationResolver: navigationResolver,
      onBackgroundMessage: (message) async {},
      authChangeStream: authRepository.userStreamValue.stream,
      platformResolver: () => BellugaConstants.settings.platform,
    );
    await repository.init();
    _listenForInvitePushUpdates(repository);
  }

  void _listenForInvitePushUpdates(PushHandlerRepositoryContract repository) {
    _pushMessageSubscription?.cancel();
    _pushMessageSubscription = repository.messageStream.listen((message) async {
      if (message.data.isEmpty) {
        return;
      }
      if (!GetIt.I.isRegistered<InvitesRepositoryContract>()) {
        return;
      }
      final invitesRepository = GetIt.I.get<InvitesRepositoryContract>();
      if (invitesRepository is PushInvitePayloadAware) {
        (invitesRepository as PushInvitePayloadAware)
            .applyInvitePushPayload(message.data);
      }
    });
  }
  Future<void> _initializeFirebaseIfAvailable() async {
    final settings = GetIt.I.get<AppDataRepository>().appData.firebaseSettings;
    if (settings == null) {
      debugPrint('[Push] Firebase settings missing; skipping init.');
      return;
    }

    debugPrint('[Push] Firebase init for project ${settings.projectId}.');
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: settings.apiKey,
        appId: settings.appId,
        messagingSenderId: settings.messagingSenderId,
        projectId: settings.projectId,
        storageBucket: settings.storageBucket,
      ),
    );
  }

  ThemeData getThemeData() =>
      GetIt.I.get<AppDataRepository>().appData.themeDataSettings.themeData();

  ThemeData getLightThemeData() => GetIt.I
      .get<AppDataRepository>()
      .appData
      .themeDataSettings
      .themeData(Brightness.light);

  ThemeData getDarkThemeData() => GetIt.I
      .get<AppDataRepository>()
      .appData
      .themeDataSettings
      .themeData(Brightness.dark);

  ThemeMode get themeMode => GetIt.I.get<AppDataRepository>().themeMode;

  @override
  State<ApplicationContract> createState() => _ApplicationContractState();
}

class _ApplicationContractState extends State<ApplicationContract> {
  @override
  Widget build(BuildContext context) {
    final appDataRepository = GetIt.I.get<AppDataRepository>();
    return StreamValueBuilder<ThemeMode?>(
      streamValue: appDataRepository.themeModeStreamValue,
      builder: (context, themeMode) {
        final resolvedThemeMode = themeMode ?? ThemeMode.system;
        return MaterialApp.router(
          themeMode: resolvedThemeMode,
          theme: widget.getLightThemeData(),
          darkTheme: widget.getDarkThemeData(),
          scrollBehavior: CustomScrollBehavior(),
          routerConfig: widget.appRouter.config(),
        );
      },
    );
  }
}
