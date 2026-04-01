import 'dart:async';

import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/telemetry_repository_contract_properties.dart';
import 'package:belluga_now/domain/repositories/value_objects/telemetry_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_queue.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_properties_codec.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

class TelemetryRepository implements TelemetryRepositoryContract {
  TelemetryRepository({
    AppDataRepositoryContract? appDataRepository,
    TelemetryQueue? queue,
    EventTrackerHandlerContract? handler,
  })  : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepositoryContract>(),
        _queue = queue ?? TelemetryQueue(),
        _handler = handler;

  final AppDataRepositoryContract _appDataRepository;
  final TelemetryQueue _queue;
  final Set<String> _idempotencyKeys = <String>{};
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _identityMergePrefix = 'telemetry_identity_merge';
  static const String _identityMergeSourcePrefix =
      'telemetry_identity_merge_source';

  EventTrackerHandlerContract? _handler;
  EventTrackerTimedEventManager? _timedEventManager;
  EventTrackerLifecycleObserver? _lifecycleObserver;
  TelemetryRepositoryContractProperties? _screenContext;

  void _debugWebTelemetry(String message, [Object? details]) {
    if (kIsWeb) {
      final payload = details == null ? message : '$message | $details';
      // ignore: avoid_print
      print('[Telemetry][Web][Repository] $payload');
    }
  }

  EventTrackerHandlerContract? get _trackerHandler {
    final settings = _appDataRepository.appData.telemetrySettings;
    if (!settings.isEnabled) return null;
    _handler ??= EventTrackerHandler.instance(settings.trackers);
    return _handler;
  }

  EventTrackerTimedEventManager? get _timedEventManagerOrNull {
    final handler = _trackerHandler;
    if (handler == null) {
      return null;
    }
    _timedEventManager ??= EventTrackerTimedEventManager(
      handler: handler,
      userDataProvider: _resolveUserData,
    );
    return _timedEventManager;
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> logEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    final handler = _trackerHandler;
    if (handler == null) {
      return telemetryRepoBool(false);
    }

    final normalizedProperties = _normalizePropertiesMap(properties);
    final idempotencyKey =
        TelemetryPropertiesCodec.readString(
      normalizedProperties,
      'idempotency_key',
    );
    if (idempotencyKey != null && _idempotencyKeys.contains(idempotencyKey)) {
      return telemetryRepoBool(true);
    }

    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    final deviceId = await authRepository.getDeviceId();
    final storedUserId = await authRepository.getUserId();
    final user = authRepository.userStreamValue.value;
    final tenantId = _appDataRepository.appData.tenantIdValue.value;
    final userId = user?.uuidValue.value ?? storedUserId;
    final userData = await _buildUserData(
      deviceId,
      storedUserId: storedUserId,
    );
    final mergedProperties =
        await _mergeContextProperties(normalizedProperties);
    final payload = EventTrackerData(
      eventName: eventName?.value,
      insertId: idempotencyKey,
      customData: {
        if (tenantId.isNotEmpty) 'tenant_id': tenantId,
        if (userId != null) 'user_id': userId,
        ...TelemetryPropertiesCodec.toRawMap(mergedProperties),
      },
    );

    final success = await _queue.enqueue(() async {
      final outcomes = await handler.logEvent(
          type: event, userData: userData, data: payload);
      final hasFailures = outcomes.any((outcome) => outcome.isFailure);
      if (hasFailures) {
        throw Exception('Telemetry delivery failed');
      }
      if (idempotencyKey != null) {
        _idempotencyKeys.add(idempotencyKey);
      }
    });
    return telemetryRepoBool(success);
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    TelemetryRepositoryContractPrimString? eventName,
    TelemetryRepositoryContractPrimMap? properties,
  }) async {
    final manager = _timedEventManagerOrNull;
    if (manager == null) {
      return null;
    }

    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    final storedUserId = await authRepository.getUserId();
    final user = authRepository.userStreamValue.value;
    final tenantId = _appDataRepository.appData.tenantIdValue.value;
    final userId = user?.uuidValue.value ?? storedUserId;
    final normalizedProperties = _normalizePropertiesMap(properties);
    final mergedProperties =
        await _mergeContextProperties(normalizedProperties);
    final mergedScreenContext =
        TelemetryPropertiesCodec.toRawMap(mergedProperties)['screen_context'];
    _debugWebTelemetry(
      'timed start',
      {
        'event': event.name,
        'name': eventName?.value ?? event.name,
        'screen_context': mergedScreenContext,
        'insert_id': TelemetryPropertiesCodec.readString(
          normalizedProperties,
          'idempotency_key',
        ),
      },
    );
    final payload = EventTrackerData(
      eventName: eventName?.value,
      insertId: TelemetryPropertiesCodec.readString(
        normalizedProperties,
        'idempotency_key',
      ),
      customData: {
        if (tenantId.isNotEmpty) 'tenant_id': tenantId,
        if (userId != null) 'user_id': userId,
        ...TelemetryPropertiesCodec.toRawMap(mergedProperties),
      },
    );

    final handle = manager.start(
      type: event,
      data: payload,
      eventName: eventName?.value,
    );
    _debugWebTelemetry('timed started', handle.id);
    return handle;
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> finishTimedEvent(
    EventTrackerTimedEventHandle handle,
  ) {
    final manager = _timedEventManagerOrNull;
    if (manager == null) {
      return Future.value(telemetryRepoBool(false));
    }
    _debugWebTelemetry('timed finish', handle.id);
    unawaited(_queue.enqueue(() async {
      final outcomes = await manager.finish(handle);
      if (outcomes.isEmpty) {
        return;
      }
      final hasFailures = outcomes.any((outcome) => outcome.isFailure);
      if (hasFailures) {
        throw Exception('Telemetry delivery failed');
      }
      _idempotencyKeys.add(handle.id);
    }));
    return Future.value(telemetryRepoBool(true));
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> flushTimedEvents() {
    final manager = _timedEventManagerOrNull;
    if (manager == null) {
      return Future.value(telemetryRepoBool(false));
    }
    _debugWebTelemetry('timed flush');
    unawaited(_queue.enqueue(() async {
      final outcomes = await manager.flush();
      if (outcomes.isEmpty) {
        return;
      }
      final hasFailures = outcomes.any((outcome) => outcome.isFailure);
      if (hasFailures) {
        throw Exception('Telemetry delivery failed');
      }
    }));
    return Future.value(telemetryRepoBool(true));
  }

  @override
  void setScreenContext(TelemetryRepositoryContractPrimMap? screenContext) {
    _screenContext = _normalizePropertiesMap(screenContext);
  }

  @override
  EventTrackerLifecycleObserver? buildLifecycleObserver() {
    final manager = _timedEventManagerOrNull;
    if (manager == null) {
      return null;
    }
    _lifecycleObserver ??=
        EventTrackerLifecycleObserver(timedEventManager: manager);
    return _lifecycleObserver;
  }

  Future<EventTrackerUserData> _buildUserData(
    String deviceId, {
    String? storedUserId,
  }) async {
    final user = GetIt.I.get<AuthRepositoryContract>().userStreamValue.value;
    final fullName = user?.profile.nameValue?.value;
    final firstName = fullName?.split(' ').first;
    final email = user?.profile.emailValue?.value;
    final userId = user?.uuidValue.value ?? storedUserId;

    return EventTrackerUserData(
      uuid: userId ?? deviceId,
      email: email,
      firstName: firstName,
      fullName: fullName,
      fcmToken: null,
      firebaseUuid: null,
      isAnonymous: user == null,
    );
  }

  Future<EventTrackerUserData> _resolveUserData() async {
    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    final deviceId = await authRepository.getDeviceId();
    final storedUserId = await authRepository.getUserId();
    return _buildUserData(
      deviceId,
      storedUserId: storedUserId,
    );
  }

  Future<TelemetryRepositoryContractProperties?> _mergeContextProperties(
    TelemetryRepositoryContractProperties? properties,
  ) async {
    final locationContext = await _buildLocationContext();
    return TelemetryPropertiesCodec.merge(
      properties: properties,
      screenContext: _screenContext,
      locationContext: locationContext,
    );
  }

  TelemetryRepositoryContractProperties? _normalizePropertiesMap(
    TelemetryRepositoryContractPrimMap? properties,
  ) {
    return properties;
  }

  Future<TelemetryRepositoryContractProperties?> _buildLocationContext() async {
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      return null;
    }

    final locationRepository = GetIt.I.get<UserLocationRepositoryContract>();
    await locationRepository.ensureLoaded();

    final coordinate = locationRepository.lastKnownLocationStreamValue.value;
    final capturedAt = locationRepository.lastKnownCapturedAtStreamValue.value;
    if (coordinate == null || capturedAt == null) {
      return null;
    }

    final freshnessWindow =
        _appDataRepository.appData.telemetryContextSettings.locationFreshness;
    if (DateTime.now().difference(capturedAt) > freshnessWindow) {
      return null;
    }

    final accuracy = locationRepository.lastKnownAccuracyStreamValue.value;

    return telemetryRepoMap({
      'lat': coordinate.latitude,
      'lng': coordinate.longitude,
      if (accuracy != null) 'accuracy_m': accuracy,
      'timestamp': capturedAt.toIso8601String(),
    });
  }

  @override
  Future<TelemetryRepositoryContractPrimBool> mergeIdentity({
    required TelemetryRepositoryContractPrimString previousUserId,
  }) async {
    final previousUserIdValue = previousUserId.value;
    final handler = _trackerHandler;
    if (handler == null || previousUserIdValue.isEmpty) {
      return telemetryRepoBool(false);
    }
    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    final user = authRepository.userStreamValue.value;
    if (user == null) {
      return telemetryRepoBool(false);
    }
    final userId = user.uuidValue.value;
    if (userId.isEmpty) {
      return telemetryRepoBool(false);
    }
    final sourceKey = '$_identityMergeSourcePrefix:$previousUserIdValue';
    final storedSource = await _storage.read(key: sourceKey);
    if (storedSource == '1') {
      return telemetryRepoBool(true);
    }
    final storageKey = '$_identityMergePrefix:$previousUserIdValue:$userId';
    final storedPair = await _storage.read(key: storageKey);
    if (storedPair == '1') {
      return telemetryRepoBool(true);
    }
    final deviceId = await authRepository.getDeviceId();
    final userData = await _buildUserData(
      deviceId,
      storedUserId: previousUserIdValue,
    );
    final success = await _queue.enqueue(() async {
      await handler.mergeIdentity(
        previousUserId: previousUserIdValue,
        userData: userData,
      );
      await _storage.write(key: sourceKey, value: '1');
      await _storage.write(key: storageKey, value: '1');
    });
    return telemetryRepoBool(success);
  }
}
