// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/configurations/custom_scroll_behavior.dart';
import 'package:belluga_now/application/configurations/belluga_constants.dart';
import 'package:belluga_now/application/router/app_router.dart';
import 'package:belluga_now/application/router/modular_app/module_settings.dart';
import 'package:belluga_now/domain/push/push_presentation_gate_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';
import 'package:belluga_now/infrastructure/repositories/push/push_payload_upsert_mixin.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stream_value/core/stream_value_builder.dart';
import 'package:push_handler/push_handler.dart';
import 'package:belluga_now/infrastructure/services/push/push_transport_configurator.dart';
import 'package:belluga_now/infrastructure/services/push/push_gatekeeper.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_handler.dart';
import 'package:belluga_now/infrastructure/services/push/push_answer_resolver.dart';
import 'package:belluga_now/infrastructure/services/push/push_action_dispatcher.dart';
import 'package:belluga_now/infrastructure/services/push/push_telemetry_forwarder.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_route_observer.dart';
import 'package:belluga_now/presentation/shared/push/controllers/push_options_controller.dart';
import 'package:belluga_now/presentation/shared/push/push_option_selector_sheet.dart';
import 'package:belluga_now/presentation/shared/push/push_step_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';

typedef PushHandlerRepositoryFactory = PushHandlerRepositoryContract Function({
  required PushTransportConfig transportConfig,
  required BuildContext? Function() contextProvider,
  required PushNavigationResolver navigationResolver,
  required Future<void> Function(RemoteMessage) onBackgroundMessage,
  Future<void> Function()? presentationGate,
  required Stream<dynamic>? authChangeStream,
  required String Function() platformResolver,
  Future<bool> Function(StepData step)? gatekeeper,
  Future<List<OptionItem>> Function(OptionSource source)? optionsBuilder,
  Future<void> Function(AnswerPayload answer, StepData step)? onStepSubmit,
  String? Function(StepData step, String? value)? stepValidator,
  Future<void> Function(ButtonData button, StepData step)? onCustomAction,
  void Function(PushEvent event)? onPushEvent,
});

abstract class ApplicationContract extends ModularAppContract {
  ApplicationContract({super.key}) : _appRouter = AppRouter();

  final AppRouter _appRouter;
  final _moduleSettings = ModuleSettings();
  StreamSubscription<RemoteMessage>? _pushMessageSubscription;
  StreamSubscription<dynamic>? _telemetryIdentitySubscription;
  PushHandlerRepositoryContract? _pushRepository;

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
      debugPrint(
          '[BuildInfo] ${info.appName} ${info.version}+${info.buildNumber} (${info.packageName})');
    } catch (_) {
      // Ignore if package info is unavailable for this platform.
    }

    await super.init();
    await _initializeFirebaseIfAvailable();
    await _initializePushHandler();
    _initializeTelemetryIdentityListener();
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
    const disablePush =
        bool.fromEnvironment('DISABLE_PUSH', defaultValue: false);
    if (disablePush) {
      debugPrint('[Push] Disabled via DISABLE_PUSH dart-define.');
      return;
    }
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
    final answerResolver = GetIt.I.isRegistered<PushAnswerResolver>()
        ? GetIt.I.get<PushAnswerResolver>()
        : null;
    final gatekeeper = PushGatekeeper(
      contextProvider: () => appRouter.navigatorKey.currentContext,
      answerResolver: answerResolver,
    );
    final optionsController = GetIt.I.get<PushOptionsController>();
    final telemetryForwarder = PushTelemetryForwarder();
    final stepValidator = PushStepValidator();
    final actionDispatcher = PushActionDispatcher(
      optionsBuilder: optionsController.resolve,
      onStepSubmit: (answer, step) async {
        await _handlePushAnswer(answer, step);
      },
      onOpenSelector: _openPushOptionSelector,
      onShowToast: _showPushToast,
    );
    final factory = repositoryFactory ??
        ({
          required PushTransportConfig transportConfig,
          required BuildContext? Function() contextProvider,
          required PushNavigationResolver navigationResolver,
          required Future<void> Function(RemoteMessage) onBackgroundMessage,
          Future<void> Function()? presentationGate,
          required Stream<dynamic>? authChangeStream,
          required String Function() platformResolver,
          Future<bool> Function(StepData step)? gatekeeper,
          Future<List<OptionItem>> Function(OptionSource source)?
              optionsBuilder,
          Future<void> Function(AnswerPayload answer, StepData step)?
              onStepSubmit,
          String? Function(StepData step, String? value)? stepValidator,
          Future<void> Function(ButtonData button, StepData step)?
              onCustomAction,
          void Function(PushEvent event)? onPushEvent,
        }) {
          return PushHandlerRepositoryDefault(
            transportConfig: transportConfig,
            contextProvider: contextProvider,
            navigationResolver: navigationResolver,
            onBackgroundMessage: onBackgroundMessage,
            presentationGate: presentationGate,
            authChangeStream: authChangeStream,
            platformResolver: platformResolver,
            gatekeeper: gatekeeper,
            optionsBuilder: optionsBuilder,
            onStepSubmit: onStepSubmit,
            stepValidator: stepValidator,
            onCustomAction: onCustomAction,
            onPushEvent: onPushEvent,
          );
        };
    final repository = factory(
      transportConfig: transportConfig,
      contextProvider: () => appRouter.navigatorKey.currentContext,
      navigationResolver: navigationResolver,
      onBackgroundMessage: (message) async {},
      presentationGate: () async {
        if (!GetIt.I.isRegistered<PushPresentationGateContract>()) {
          return;
        }
        final gate = GetIt.I.get<PushPresentationGateContract>();
        if (gate.isReady) {
          return;
        }
        await gate.waitUntilReady();
      },
      authChangeStream: authRepository.userStreamValue.stream,
      platformResolver: () => BellugaConstants.settings.platform,
      gatekeeper: gatekeeper.check,
      optionsBuilder: optionsController.resolve,
      onStepSubmit: (answer, step) => _handlePushAnswer(answer, step),
      stepValidator: stepValidator.validate,
      onCustomAction: (button, step) => actionDispatcher.dispatch(
        button: button,
        step: step,
      ),
      onPushEvent: (event) {
        unawaited(telemetryForwarder.forward(event));
      },
    );
    try {
      await repository.init();
    } catch (e) {
      debugPrint('[Push] Init failed: $e');
      return;
    }
    _pushRepository = repository;
    _listenForInvitePushUpdates(repository);
  }

  Future<List<dynamic>?> _openPushOptionSelector(
    PushOptionSelectorPayload payload,
  ) async {
    final context = appRouter.navigatorKey.currentContext;
    if (context == null || !context.mounted) {
      return null;
    }
    return PushOptionSelectorSheet.show(
      context: context,
      title: payload.title,
      body: payload.body,
      layout: payload.layout,
      gridColumns: payload.gridColumns,
      selectionMode: payload.selectionMode,
      options: payload.options,
      minSelected: payload.minSelected,
      maxSelected: payload.maxSelected,
      initialSelected: payload.initialSelected,
    );
  }

  void _showPushToast(String message) {
    if (message.isEmpty) {
      return;
    }
    final context = appRouter.navigatorKey.currentContext;
    final messenger = context != null ? ScaffoldMessenger.maybeOf(context) : null;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  void _initializeTelemetryIdentityListener() {
    if (!GetIt.I.isRegistered<AuthRepositoryContract>() ||
        !GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }
    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    final telemetryRepository = GetIt.I.get<TelemetryRepositoryContract>();
    _telemetryIdentitySubscription?.cancel();
    _telemetryIdentitySubscription =
        authRepository.userStreamValue.stream.listen((user) async {
      if (user == null) {
        return;
      }
      final storedUserId = await authRepository.getUserId();
      if (storedUserId == null || storedUserId.isEmpty) {
        return;
      }
      await telemetryRepository.mergeIdentity(
        previousUserId: storedUserId,
      );
    });
    final currentUser = authRepository.userStreamValue.value;
    if (currentUser != null) {
      unawaited(_handleTelemetryIdentityMerge(
        authRepository: authRepository,
        telemetryRepository: telemetryRepository,
      ));
    }
  }

  Future<void> _handleTelemetryIdentityMerge({
    required AuthRepositoryContract authRepository,
    required TelemetryRepositoryContract telemetryRepository,
  }) async {
    final storedUserId = await authRepository.getUserId();
    if (storedUserId == null || storedUserId.isEmpty) {
      return;
    }
    await telemetryRepository.mergeIdentity(
      previousUserId: storedUserId,
    );
  }

  Future<void> _handlePushAnswer(
    AnswerPayload answer,
    StepData step,
  ) async {
    if (GetIt.I.isRegistered<PushAnswerHandler>()) {
      final handler = GetIt.I.get<PushAnswerHandler>();
      await handler.handle(answer, step);
    }
  }

  @visibleForTesting
  Future<void> debugPresentPushMessage(String messageId) async {
    await _pushRepository?.debugInjectMessageId(messageId);
  }

  Future<void> _initializeFirebaseIfAvailable() async {
    final settings =
        GetIt.I.get<AppDataRepositoryContract>().appData.firebaseSettings;
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

  ThemeData getThemeData() => GetIt.I
      .get<AppDataRepositoryContract>()
      .appData
      .themeDataSettings
      .themeData();

  ThemeData getLightThemeData() => GetIt.I
      .get<AppDataRepositoryContract>()
      .appData
      .themeDataSettings
      .themeData(Brightness.light);

  ThemeData getDarkThemeData() => GetIt.I
      .get<AppDataRepositoryContract>()
      .appData
      .themeDataSettings
      .themeData(Brightness.dark);

  ThemeMode get themeMode => GetIt.I.get<AppDataRepositoryContract>().themeMode;

  @override
  State<ApplicationContract> createState() => _ApplicationContractState();
}

class _ApplicationContractState extends State<ApplicationContract>
    with WidgetsBindingObserver {
  bool _didTrackAppInit = false;
  bool _appInitInFlight = false;
  AppLifecycleState? _lastLifecycleState;
  EventTrackerLifecycleObserver? _telemetryLifecycleObserver;
  EventTrackerTimedEventHandle? _routerTimedEvent;
  String? _lastRouterSignature;
  Future<void> _routerTrackPending = Future.value();
  VoidCallback? _routerListener;
  final List<AppLifecycleState> _lifecycleStateBuffer = [];
  Timer? _lifecycleDebounceTimer;
  static const Duration _lifecycleDebounceWindow = Duration(milliseconds: 400);
  static const int _appInitMaxRetries = 10;
  static const Duration _appInitRetryDelay = Duration(milliseconds: 500);
  int _appInitRetryCount = 0;
  Timer? _appInitRetryTimer;

  void _debugWebTelemetry(String message, [Object? details]) {
    if (kIsWeb) {
      final payload = details == null ? message : '$message | $details';
      // ignore: avoid_print
      print('[Telemetry][Web][AppRouter] $payload');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerTelemetryLifecycleObserver();
    _registerRouterTelemetryObserver();
    unawaited(_trackAppInit());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_telemetryLifecycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_telemetryLifecycleObserver!);
      _telemetryLifecycleObserver = null;
    }
    if (_routerListener != null) {
      widget.appRouter.removeListener(_routerListener!);
      _routerListener = null;
    }
    _appInitRetryTimer?.cancel();
    _lifecycleDebounceTimer?.cancel();
    super.dispose();
  }

  void _registerRouterTelemetryObserver() {
    if (!kIsWeb || _routerListener != null) return;

    void enqueueCurrentRoute(String reason) {
      final route = widget.appRouter.topRoute;
      _debugWebTelemetry(reason, {'route': route.name, 'match': route.match});
      _enqueueRouterTrack(route);
    }

    _routerListener = () => enqueueCurrentRoute('listener fired');
    widget.appRouter.addListener(_routerListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      enqueueCurrentRoute('post frame enqueue');
    });
  }

  void _enqueueRouterTrack(RouteData routeData) {
    _debugWebTelemetry(
      'enqueue track',
      {
        'route': routeData.name,
        'match': routeData.match,
      },
    );
    _routerTrackPending = _routerTrackPending
        .then((_) => _trackRouterRoute(routeData))
        .catchError((_) {});
  }

  Future<void> _trackRouterRoute(RouteData routeData) async {
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }
    final signature = _buildRouterSignature(routeData);
    if (signature == _lastRouterSignature) {
      _debugWebTelemetry('skip (same signature)', signature);
      return;
    }
    _lastRouterSignature = signature;
    _finishRouterTimedEvent();
    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    final screenContext = _buildRouterScreenContext(routeData);
    telemetry.setScreenContext(screenContext);
    _routerTimedEvent = await telemetry.startTimedEvent(
      EventTrackerEvents.viewContent,
      eventName: 'screen_view',
      properties: {
        'screen_context': screenContext,
      },
    );
    _debugWebTelemetry(
      'timed event started',
      {
        'route': routeData.name,
        'handle': _routerTimedEvent?.id,
      },
    );
  }

  void _finishRouterTimedEvent() {
    final handle = _routerTimedEvent;
    if (handle == null) {
      return;
    }
    _routerTimedEvent = null;
    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    _debugWebTelemetry('timed event finish', handle.id);
    unawaited(telemetry.finishTimedEvent(handle));
  }

  String _buildRouterSignature(RouteData routeData) {
    return '${routeData.name}|${routeData.match}|'
        '${routeData.params.rawMap}|${routeData.queryParams.rawMap}';
  }

  Map<String, dynamic> _buildRouterScreenContext(RouteData routeData) {
    final params = {
      ...routeData.params.rawMap,
      ...routeData.queryParams.rawMap,
    };
    final sanitized = _sanitizeRouteParams(params);
    return {
      'route_name': routeData.name,
      'route_type': routeData.type.runtimeType.toString(),
      'is_overlay': false,
      if (sanitized != null && sanitized.isNotEmpty) 'route_params': sanitized,
    };
  }

  Map<String, dynamic>? _sanitizeRouteParams(
    Map<String, dynamic> params,
  ) {
    if (params.isEmpty) {
      return null;
    }
    final sanitized = <String, dynamic>{};
    params.forEach((key, value) {
      final safeValue = _sanitizeJsonValue(value);
      if (safeValue != null) {
        sanitized[key.toString()] = safeValue;
      }
    });
    return sanitized.isEmpty ? null : sanitized;
  }

  Object? _sanitizeJsonValue(Object? value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is Map) {
      final sanitized = <String, dynamic>{};
      value.forEach((key, nested) {
        final safeValue = _sanitizeJsonValue(nested);
        if (safeValue != null) {
          sanitized[key.toString()] = safeValue;
        }
      });
      return sanitized.isEmpty ? null : sanitized;
    }
    if (value is Iterable) {
      final sanitized =
          value.map(_sanitizeJsonValue).where((item) => item != null).toList();
      return sanitized.isEmpty ? null : sanitized;
    }
    return null;
  }

  void _registerTelemetryLifecycleObserver() {
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }
    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    final observer = telemetry.buildLifecycleObserver();
    if (observer == null) {
      return;
    }
    _telemetryLifecycleObserver = observer;
    WidgetsBinding.instance.addObserver(observer);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_lastLifecycleState == state) {
      return;
    }
    final previousState = _lastLifecycleState;
    _lastLifecycleState = state;
    if (!kIsWeb) {
      _bufferAppLifecycle(state);
    }
    if (state == AppLifecycleState.resumed &&
        (previousState == AppLifecycleState.paused ||
            previousState == AppLifecycleState.detached)) {
      _didTrackAppInit = false;
      _appInitRetryCount = 0;
      _appInitRetryTimer?.cancel();
      unawaited(_trackAppInit());
    }
  }

  Future<void> _trackAppInit() async {
    if (_didTrackAppInit || _appInitInFlight) {
      return;
    }
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      _scheduleAppInitRetry();
      return;
    }
    if (!GetIt.I.isRegistered<AuthRepositoryContract>()) {
      _scheduleAppInitRetry();
      return;
    }

    _appInitInFlight = true;
    _appInitRetryTimer?.cancel();
    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    var success = false;
    try {
      success = await telemetry.logEvent(
        EventTrackerEvents.openApp,
        eventName: 'app_init',
      );
    } catch (_) {
      success = false;
    }
    _appInitInFlight = false;
    if (success) {
      _didTrackAppInit = true;
      _appInitRetryTimer?.cancel();
    } else {
      _scheduleAppInitRetry();
    }
  }

  void _scheduleAppInitRetry() {
    if (_appInitRetryTimer != null ||
        _appInitRetryCount >= _appInitMaxRetries) {
      return;
    }
    _appInitRetryCount += 1;
    _appInitRetryTimer = Timer(_appInitRetryDelay, () {
      _appInitRetryTimer = null;
      if (!mounted) return;
      unawaited(_trackAppInit());
    });
  }

  void _bufferAppLifecycle(AppLifecycleState state) {
    _lifecycleStateBuffer.add(state);
    _lifecycleDebounceTimer?.cancel();
    _lifecycleDebounceTimer = Timer(_lifecycleDebounceWindow, () {
      _lifecycleDebounceTimer = null;
      if (!mounted || _lifecycleStateBuffer.isEmpty) {
        _lifecycleStateBuffer.clear();
        return;
      }
      final sequence = _lifecycleStateBuffer
          .map((item) => item.name)
          .toList(growable: false);
      final finalState = _lifecycleStateBuffer.last;
      _lifecycleStateBuffer.clear();
      _trackAppLifecycle(finalState, sequence);
    });
  }

  void _trackAppLifecycle(
    AppLifecycleState finalState,
    List<String> sequence,
  ) {
    if (!GetIt.I.isRegistered<TelemetryRepositoryContract>()) {
      return;
    }
    final telemetry = GetIt.I.get<TelemetryRepositoryContract>();
    unawaited(
      telemetry.logEvent(
        EventTrackerEvents.openApp,
        eventName: 'app_lifecycle',
        properties: {
          'state': finalState.name,
          'sequence': sequence,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appDataRepository = GetIt.I.get<AppDataRepositoryContract>();
    return StreamValueBuilder<ThemeMode?>(
      streamValue: appDataRepository.themeModeStreamValue,
      builder: (context, themeMode) {
        final resolvedThemeMode = themeMode ?? ThemeMode.system;
        return MaterialApp.router(
          themeMode: resolvedThemeMode,
          theme: widget.getLightThemeData(),
          darkTheme: widget.getDarkThemeData(),
          scrollBehavior: CustomScrollBehavior(),
          routerConfig: widget.appRouter.config(
            navigatorObservers: () =>
                kIsWeb ? const [] : [TelemetryRouteObserver()],
          ),
        );
      },
    );
  }
}
