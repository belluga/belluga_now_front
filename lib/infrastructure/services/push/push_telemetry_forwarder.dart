import 'package:belluga_now/domain/repositories/telemetry_repository_contract.dart';
import 'package:event_tracker_handler/event_tracker_handler.dart';
import 'package:get_it/get_it.dart';
import 'package:push_handler/push_handler.dart';

class PushTelemetryForwarder {
  PushTelemetryForwarder({TelemetryRepositoryContract? telemetryRepository})
      : _telemetryRepository =
            telemetryRepository ?? GetIt.I.get<TelemetryRepositoryContract>();

  final TelemetryRepositoryContract _telemetryRepository;

  Future<void> forward(PushEvent event) async {
    final trackerEvent = _mapEvent(event.type);
    final idempotencyKey = _buildIdempotencyKey(event);
    await _telemetryRepository.logEvent(
      trackerEvent,
      eventName: 'push_${event.type}',
      properties: {
        'push_id': event.pushId,
        'message_instance_id': event.messageInstanceId,
        'step_slug': event.stepSlug,
        'step_type': event.stepType,
        'button_key': event.buttonKey,
        'action_type': event.actionType,
        'route_key': event.routeKey,
        'app_state': event.appState,
        'source': event.source,
        'timestamp': event.timestamp.toIso8601String(),
        if (event.metadata != null) ...event.metadata!,
        'idempotency_key': idempotencyKey,
      },
    );
  }

  EventTrackerEvents _mapEvent(String type) {
    switch (type) {
      case 'button_tap':
        return EventTrackerEvents.buttonClick;
      case 'submit':
        return EventTrackerEvents.selectItem;
      default:
        return EventTrackerEvents.viewContent;
    }
  }

  String _buildIdempotencyKey(PushEvent event) {
    return [
      'push',
      event.type,
      event.pushId,
      event.messageInstanceId ?? '',
      event.stepSlug ?? '',
      event.buttonKey ?? '',
    ].join(':');
  }
}
