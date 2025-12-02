import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_item_dto.dart';

class EventSummaryDTO {
  const EventSummaryDTO({required this.items});

  final List<EventSummaryItemDTO> items;
}
