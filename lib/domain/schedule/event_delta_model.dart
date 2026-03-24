export 'event_delta_type.dart';

import 'package:belluga_now/domain/schedule/event_delta_type.dart';

typedef EventDeltaModelPrimString = String;
typedef EventDeltaModelPrimInt = int;
typedef EventDeltaModelPrimBool = bool;
typedef EventDeltaModelPrimDouble = double;
typedef EventDeltaModelPrimDateTime = DateTime;
typedef EventDeltaModelPrimDynamic = dynamic;

class EventDeltaModel {
  EventDeltaModel({
    required this.eventId,
    required this.type,
    this.updatedAt,
    this.lastEventId,
  });

  final EventDeltaModelPrimString eventId;
  final EventDeltaType type;
  final EventDeltaModelPrimDateTime? updatedAt;
  final EventDeltaModelPrimString? lastEventId;
}
