import 'package:belluga_now/domain/schedule/schedule_summary_item_model.dart';

class EventSummaryItemDTO {
  const EventSummaryItemDTO({
    required this.dateTimeStart,
    this.color,
  });

  final String dateTimeStart;
  final String? color;

  ScheduleSummaryItemModel toDomain() {
    return ScheduleSummaryItemModel(
      dateTimeStart: DateTime.parse(dateTimeStart),
      color: color,
    );
  }
}
