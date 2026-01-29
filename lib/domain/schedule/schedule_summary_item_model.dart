import 'package:belluga_now/infrastructure/dal/dto/schedule/event_summary_item_dto.dart';

class ScheduleSummaryItemModel {
  final String? color;
  final DateTime dateTimeStart;

  ScheduleSummaryItemModel({
    this.color,
    required this.dateTimeStart,
  });

  factory ScheduleSummaryItemModel.fromDto(EventSummaryItemDTO dto) {
    return ScheduleSummaryItemModel(
      dateTimeStart: DateTime.parse(dto.dateTimeStart),
      color: dto.color,
    );
  }
}
