import 'package:belluga_now/domain/schedule/value_objects/schedule_summary_color_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class ScheduleSummaryItemModel {
  final ScheduleSummaryColorValue colorValue;
  final DateTimeValue dateTimeStartValue;

  ScheduleSummaryItemModel({
    ScheduleSummaryColorValue? colorValue,
    required this.dateTimeStartValue,
  }) : colorValue = colorValue ?? ScheduleSummaryColorValue();

  String? get color =>
      colorValue.value.trim().isEmpty ? null : colorValue.value;
  DateTime get dateTimeStart {
    final value = dateTimeStartValue.value;
    if (value == null) {
      throw StateError('dateTimeStart should not be null');
    }
    return value;
  }
}
