import 'dart:async';

import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_queue.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

class TelemetryRepository implements TelemetryRepositoryContract {
  TelemetryRepository({
    AppDataRepository? appDataRepository,
    TelemetryQueue? queue,
    EventTrackerHandlerContract? handler,
  })  : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepository>(),
        _queue = queue ?? TelemetryQueue(),
        _handler = handler;

  final AppDataRepository _appDataRepository;
  final TelemetryQueue _queue;
  final Set<String> _idempotencyKeys = <String>{};
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _identityMergePrefix = 'telemetry_identity_merge';
  static const String _identityMergeSourcePrefix =
      'telemetry_identity_merge_source';

  EventTrackerHandlerContract? _handler;
  EventTrackerTimedEventManager? _timedEventManager;
  EventTrackerLifecycleObserver? _lifecycleObserver;
  Map<String, dynamic>? _screenContext;

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
  Future<bool> logEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
  }) async {
    final handler = _trackerHandler;
    if (handler == null) {
      return false;
    }

    final idempotencyKey = properties?['idempotency_key'] as String?;
    if (idempotencyKey != null && _idempotencyKeys.contains(idempotencyKey)) {
      return true;
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
    final mergedProperties = await _mergeContextProperties(properties);
    final payload = EventTrackerData(
      eventName: eventName,
      insertId: idempotencyKey,
      customData: {
        if (tenantId.isNotEmpty) 'tenant_id': tenantId,
        if (userId != null) 'user_id': userId,
        if (mergedProperties.isNotEmpty) ...mergedProperties,
      },
    );

    return _queue.enqueue(() async {
      final outcomes =
          await handler.logEvent(type: event, userData: userData, data: payload);
      final hasFailures = outcomes.any((outcome) => outcome.isFailure);
      if (hasFailures) {
        throw Exception('Telemetry delivery failed');
      }
      if (idempotencyKey != null) {
        _idempotencyKeys.add(idempotencyKey);
      }
    });
  }

  @override
  Future<EventTrackerTimedEventHandle?> startTimedEvent(
    EventTrackerEvents event, {
    String? eventName,
    Map<String, dynamic>? properties,
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
    final mergedProperties = await _mergeContextProperties(properties);
    _debugWebTelemetry(
      'timed start',
      {
        'event': event.name,
        'name': eventName ?? event.name,
        'screen_context': mergedProperties['screen_context'],
        'insert_id': properties?['idempotency_key'],
      },
    );
    final payload = EventTrackerData(
      eventName: eventName,
      insertId: properties?['idempotency_key'] as String?,
      customData: {
        if (tenantId.isNotEmpty) 'tenant_id': tenantId,
        if (userId != null) 'user_id': userId,
        if (mergedProperties.isNotEmpty) ...mergedProperties,
      },
    );

    final handle = manager.start(
      type: event,
      data: payload,
      eventName: eventName,
    );
    _debugWebTelemetry('timed started', handle.id);
    return handle;
  }

  @override
  Future<bool> finishTimedEvent(EventTrackerTimedEventHandle handle) {
    final manager = _timedEventManagerOrNull;
    if (manager == null) {
      return Future.value(false);
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
    return Future.value(true);
  }

  @override
  Future<bool> flushTimedEvents() {
    final manager = _timedEventManagerOrNull;
    if (manager == null) {
      return Future.value(false);
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
    return Future.value(true);
  }

  @override
  void setScreenContext(Map<String, dynamic>? screenContext) {
    _screenContext = screenContext;
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

  Future<Map<String, dynamic>> _mergeContextProperties(
    Map<String, dynamic>? properties,
  ) async {
    final merged = <String, dynamic>{};
    if (_screenContext != null &&
        !(properties?.containsKey('screen_context') ?? false)) {
      merged['screen_context'] = _screenContext;
    }

    if (!(properties?.containsKey('location_context') ?? false)) {
      final locationContext = await _buildLocationContext();
      if (locationContext != null) {
        merged['location_context'] = locationContext;
      }
    }

    if (properties != null) {
      merged.addAll(properties);
    }

    return merged;
  }

  Future<Map<String, dynamic>?> _buildLocationContext() async {
    if (!GetIt.I.isRegistered<UserLocationRepositoryContract>()) {
      return null;
    }

    final locationRepository =
        GetIt.I.get<UserLocationRepositoryContract>();
    try {
      await locationRepository.ensureLoaded();
    } catch (_) {
      return null;
    }

    final coordinate = locationRepository.lastKnownLocationStreamValue.value;
    final capturedAt =
        locationRepository.lastKnownCapturedAtStreamValue.value;
    if (coordinate == null || capturedAt == null) {
      return null;
    }

    final freshnessWindow =
        _appDataRepository.appData.telemetryContextSettings.locationFreshness;
    if (DateTime.now().difference(capturedAt) > freshnessWindow) {
      return null;
    }

    final accuracy =
        locationRepository.lastKnownAccuracyStreamValue.value;

    return {
      'lat': coordinate.latitude,
      'lng': coordinate.longitude,
      if (accuracy != null) 'accuracy_m': accuracy,
      'timestamp': capturedAt.toIso8601String(),
    };
  }

  @override
  Future<bool> mergeIdentity({
    required String previousUserId,
  }) async {
    final handler = _trackerHandler;
    if (handler == null || previousUserId.isEmpty) {
      return false;
    }
    final authRepository = GetIt.I.get<AuthRepositoryContract>();
    final user = authRepository.userStreamValue.value;
    if (user == null) {
      return false;
    }
    final userId = user.uuidValue.value;
    if (userId.isEmpty) {
      return false;
    }
    final sourceKey = '$_identityMergeSourcePrefix:$previousUserId';
    final storedSource = await _storage.read(key: sourceKey);
    if (storedSource == '1') {
      return true;
    }
    final storageKey = '$_identityMergePrefix:$previousUserId:$userId';
    final storedPair = await _storage.read(key: storageKey);
    if (storedPair == '1') {
      return true;
    }
    final deviceId = await authRepository.getDeviceId();
    final userData = await _buildUserData(
      deviceId,
      storedUserId: previousUserId,
    );
    return _queue.enqueue(() async {
      await handler.mergeIdentity(
        previousUserId: previousUserId,
        userData: userData,
      );
      await _storage.write(key: sourceKey, value: '1');
      await _storage.write(key: storageKey, value: '1');
    });
  }
}
