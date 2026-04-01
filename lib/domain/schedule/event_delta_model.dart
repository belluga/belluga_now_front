export 'event_delta_type.dart';

import 'package:belluga_now/domain/schedule/event_delta_type.dart';
import 'package:belluga_now/domain/schedule/value_objects/schedule_event_id_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class EventDeltaModel {
  EventDeltaModel({
    required this.eventIdValue,
    required this.type,
    this.updatedAtValue,
    this.lastEventIdValue,
  });

  final ScheduleEventIdValue eventIdValue;
  final EventDeltaType type;
  final DateTimeValue? updatedAtValue;
  final ScheduleEventIdValue? lastEventIdValue;

  String get eventId => eventIdValue.value;
  DateTime? get updatedAt => updatedAtValue?.value;
  String? get lastEventId => lastEventIdValue?.value;
}
