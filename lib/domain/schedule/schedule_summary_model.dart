import 'package:belluga_now/domain/schedule/schedule_summary_item_model.dart';
import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_dto.dart';

class ScheduleSummaryModel {
  final List<ScheduleSummaryItemModel> items;

  ScheduleSummaryModel({
    required this.items,
  });

  DateTime get today =>
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int get initialIndex => today.difference(firstDayRange).inDays;

  int get totalItems {
    final int previous2Date = today.difference(firstDayRange).inDays;
    final int date2Last = lastDayRange.difference(today).inDays;

    return previous2Date + date2Last + 1;
  }

  DateTime get lastDayRange {
    items.sort((a, b) => a.dateTimeStart.compareTo(b.dateTimeStart));

    return DateTime(
        items.last.dateTimeStart.year, items.last.dateTimeStart.month, 1);
  }

  DateTime get firstDayRange {
    items.sort((a, b) => a.dateTimeStart.compareTo(b.dateTimeStart));

    return DateTime(
        items.first.dateTimeStart.year, items.first.dateTimeStart.month, 1);
  }

  factory ScheduleSummaryModel.fromDTO(EventSummaryDTO dto) {
    return ScheduleSummaryModel(
      items: dto.items.map((e) => ScheduleSummaryItemModel.fromDTO(e)).toList(),
    );
  }
}
