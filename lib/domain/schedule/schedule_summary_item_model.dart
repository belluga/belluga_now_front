import 'package:belluga_now/domain/schedule/value_objects/schedule_summary_color_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class ScheduleSummaryItemModel {
  final ScheduleSummaryColorValue colorValue;
  final DateTimeValue dateTimeStartValue;

  ScheduleSummaryItemModel({
    Object? color,
    required Object dateTimeStart,
  })  : colorValue = _parseColor(color),
        dateTimeStartValue = _parseDateTime(dateTimeStart);

  String? get color =>
      colorValue.value.trim().isEmpty ? null : colorValue.value;
  DateTime get dateTimeStart {
    final value = dateTimeStartValue.value;
    if (value == null) {
      throw StateError('dateTimeStart should not be null');
    }
    return value;
  }

  static ScheduleSummaryColorValue _parseColor(Object? raw) {
    if (raw is ScheduleSummaryColorValue) {
      return raw;
    }
    final value = ScheduleSummaryColorValue();
    value.parse(raw?.toString());
    return value;
  }

  static DateTimeValue _parseDateTime(Object raw) {
    if (raw is DateTimeValue) {
      return raw;
    }
    final value = DateTimeValue(isRequired: true);
    if (raw is DateTime) {
      value.parse(raw.toIso8601String());
      return value;
    }
    value.parse(raw.toString());
    return value;
  }
}
