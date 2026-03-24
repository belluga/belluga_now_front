import 'package:belluga_now/domain/schedule/event_delta_model.dart';

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
      updatedAt:
          updatedAtRaw != null ? DateTime.tryParse(updatedAtRaw) : null,
      lastEventId: lastEventId,
    );
  }

  EventDeltaModel toDomain() {
    return EventDeltaModel(
      eventId: eventId,
      type: _parseEventDeltaType(type),
      updatedAt: updatedAt,
      lastEventId: lastEventId,
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
