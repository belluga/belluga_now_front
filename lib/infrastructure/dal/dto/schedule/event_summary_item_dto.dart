import 'package:belluga_now/domain/schedule/schedule_summary_item_model.dart';
import 'package:belluga_now/domain/schedule/value_objects/schedule_summary_color_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class EventSummaryItemDTO {
  const EventSummaryItemDTO({
    required this.dateTimeStart,
    this.color,
  });

  final String dateTimeStart;
  final String? color;

  ScheduleSummaryItemModel toDomain() {
    final dateTimeStartValue = DateTimeValue(isRequired: true)
      ..parse(dateTimeStart);
    final colorValue = ScheduleSummaryColorValue()..parse(color);

    return ScheduleSummaryItemModel(
      dateTimeStartValue: dateTimeStartValue,
      colorValue: colorValue,
    );
  }
}
