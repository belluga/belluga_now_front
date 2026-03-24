import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_item_dto.dart';
import 'package:belluga_now/domain/schedule/schedule_summary_model.dart';

class EventSummaryDTO {
  const EventSummaryDTO({required this.items});

  final List<EventSummaryItemDTO> items;

  ScheduleSummaryModel toDomain() {
    return ScheduleSummaryModel(
      items: items.map((item) => item.toDomain()).toList(growable: false),
    );
  }
}
