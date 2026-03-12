export 'event_delta_type.dart';

import 'package:belluga_now/domain/schedule/event_delta_type.dart';

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
