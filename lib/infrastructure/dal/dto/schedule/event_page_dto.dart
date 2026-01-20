import 'package:belluga_now/infrastructure/dal/dto/schedule/event_dto.dart';

class EventPageDTO {
  EventPageDTO({
    required this.events,
    required this.hasMore,
  });

  final List<EventDTO> events;
  final bool hasMore;

  factory EventPageDTO.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => EventDTO.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    return EventPageDTO(
      events: items,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
