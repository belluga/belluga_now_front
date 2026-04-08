import 'package:belluga_now/domain/schedule/event_model.dart';

class TenantHomeAgendaDisplayState {
  TenantHomeAgendaDisplayState({
    required List<EventModel> events,
  }) : events = List<EventModel>.unmodifiable(events);

  final List<EventModel> events;

  bool get isEmpty => events.isEmpty;
}
