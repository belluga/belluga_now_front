import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_dto.dart';

class EventPageDTO {
  EventPageDTO({
    required this.events,
    required this.hasMore,
  });

  final List<EventDTO> events;
  final bool hasMore;
}
