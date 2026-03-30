import 'package:belluga_now/domain/schedule/event_delta_model.dart';
import 'package:belluga_now/domain/schedule/value_objects/schedule_event_id_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class EventDeltaDTO {
  EventDeltaDTO({
    required this.eventId,
    required this.type,
    this.updatedAt,
    this.lastEventId,
  });

  final String eventId;
  final String type;
  final DateTime? updatedAt;
  final String? lastEventId;

  factory EventDeltaDTO.fromJson(
    Map<String, dynamic> json, {
    String? lastEventId,
  }) {
    final updatedAtRaw = json['updated_at']?.toString();
    return EventDeltaDTO(
      eventId: json['event_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      updatedAt: updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null,
      lastEventId: lastEventId,
    );
  }

  EventDeltaModel toDomain() {
    final eventIdValue = ScheduleEventIdValue()..parse(eventId);
    final updatedAtValue = updatedAt != null
        ? (DateTimeValue(
            defaultValue: updatedAt,
            isRequired: false,
          )..parse(updatedAt?.toIso8601String()))
        : null;

    ScheduleEventIdValue? lastEventIdValue;
    if (lastEventId != null && lastEventId!.trim().isNotEmpty) {
      lastEventIdValue = ScheduleEventIdValue()..parse(lastEventId);
    }

    return EventDeltaModel(
      eventIdValue: eventIdValue,
      type: _parseEventDeltaType(type),
      updatedAtValue: updatedAtValue,
      lastEventIdValue: lastEventIdValue,
    );
  }

  EventDeltaType _parseEventDeltaType(String rawType) {
    switch (rawType) {
      case 'event.created':
        return EventDeltaType.created;
      case 'event.updated':
        return EventDeltaType.updated;
      case 'event.deleted':
        return EventDeltaType.deleted;
      default:
        return EventDeltaType.unknown;
    }
  }
}
