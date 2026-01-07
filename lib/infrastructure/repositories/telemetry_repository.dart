import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/infrastructure/repositories/app_data_repository.dart';
import 'package:belluga_now/infrastructure/services/telemetry/telemetry_queue.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
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
    final user = authRepository.userStreamValue.value;
    final tenantId = _appDataRepository.appData.tenantIdValue.value;
    final userId = user?.uuidValue.value;
    final userData = await _buildUserData(deviceId);
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

  Future<EventTrackerUserData> _buildUserData(String deviceId) async {
    final user = GetIt.I.get<AuthRepositoryContract>().userStreamValue.value;
    final fullName = user?.profile.nameValue?.value;
    final firstName = fullName?.split(' ').first;
    final email = user?.profile.emailValue?.value;
    final userId = user?.uuidValue.value;

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
}
