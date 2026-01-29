enum EventDeltaType {
  created,
  updated,
  deleted,
  unknown,
}

class EventDeltaModel {
  EventDeltaModel({
    required this.eventId,
    required this.type,
    this.updatedAt,
    this.lastEventId,
  });

  final String eventId;
  final EventDeltaType type;
  final DateTime? updatedAt;
  final String? lastEventId;
}
