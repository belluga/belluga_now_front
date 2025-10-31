import 'package:belluga_now/domain/schedule/schedule_summary_item_model.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_dto.dart';

class ScheduleSummaryModel {
  final List<ScheduleSummaryItemModel> items;

  ScheduleSummaryModel({
    required this.items,
  });

  static const int _daysBackwardLimit = 15;
  static const int _monthsForwardLimit = 3;

  DateTime get today =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int get initialIndex => today.difference(firstDayRange).inDays;

  int get totalItems {
    final int previous2Date = today.difference(firstDayRange).inDays;
    final int date2Last = lastDayRange.difference(today).inDays;

    return previous2Date + date2Last + 1;
  }

  DateTime get lastDayRange {
    final future =
        DateTime(today.year, today.month + _monthsForwardLimit, today.day);
    return DateTime(future.year, future.month, future.day);
  }

  DateTime get firstDayRange {
    final start = today.subtract(Duration(days: _daysBackwardLimit));
    return DateTime(start.year, start.month, start.day);
  }

  factory ScheduleSummaryModel.fromDTO(EventSummaryDTO dto) {
    return ScheduleSummaryModel(
      items: dto.items.map((e) => ScheduleSummaryItemModel.fromDTO(e)).toList(),
    );
  }
}
