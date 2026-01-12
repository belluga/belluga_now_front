import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_queue.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

class TelemetryRepository implements TelemetryRepositoryContract {
  TelemetryRepository({
    AppDataRepository? appDataRepository,
    TelemetryQueue? queue,
  })  : _appDataRepository =
            appDataRepository ?? GetIt.I.get<AppDataRepository>(),
        _queue = queue ?? TelemetryQueue();

  final AppDataRepository _appDataRepository;
  final TelemetryQueue _queue;
  final Set<String> _idempotencyKeys = <String>{};
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _identityMergePrefix = 'telemetry_identity_merge';

  EventTrackerHandler? _handler;

  EventTrackerHandler? get _trackerHandler {
    final settings = _appDataRepository.appData.telemetrySettings;
    if (!settings.isEnabled) return null;
    _handler ??= EventTrackerHandler.instance(settings.trackers);
    return _handler;
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
    final anonymousUserId = await authRepository.getAnonymousUserId();
    final user = authRepository.userStreamValue.value;
    final tenantId = _appDataRepository.appData.tenantIdValue.value;
    final userId = user?.uuidValue.value ?? anonymousUserId;
    final userData = await _buildUserData(
      deviceId,
      anonymousUserId: anonymousUserId,
    );
    final payload = EventTrackerData(
      eventName: eventName,
      customData: {
        if (tenantId.isNotEmpty) 'tenant_id': tenantId,
        if (userId != null) 'user_id': userId,
        if (properties != null) ...properties,
      },
    );

    return _queue.enqueue(() async {
      await handler.logEvent(type: event, userData: userData, data: payload);
      if (idempotencyKey != null) {
        _idempotencyKeys.add(idempotencyKey);
      }
    });
  }

  Future<EventTrackerUserData> _buildUserData(
    String deviceId, {
    String? anonymousUserId,
  }) async {
    final user = GetIt.I.get<AuthRepositoryContract>().userStreamValue.value;
    final fullName = user?.profile.nameValue?.value;
    final firstName = fullName?.split(' ').first;
    final email = user?.profile.emailValue?.value;
    final userId = user?.uuidValue.value ?? anonymousUserId;

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
    final storageKey = '$_identityMergePrefix:$previousUserId:$userId';
    final stored = await _storage.read(key: storageKey);
    if (stored == '1') {
      return true;
    }
    final deviceId = await authRepository.getDeviceId();
    final userData = await _buildUserData(
      deviceId,
      anonymousUserId: previousUserId,
    );
    return _queue.enqueue(() async {
      await handler.mergeIdentity(
        previousUserId: previousUserId,
        userData: userData,
      );
      await _storage.write(key: storageKey, value: '1');
    });
  }
}
