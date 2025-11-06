import 'package:belluga_now/infrastructure/services/dal/dto/schedule/event_summary_item_dto.dart';

class ScheduleSummaryItemModel {
  final String? color;
  final DateTime dateTimeStart;

  ScheduleSummaryItemModel({
    this.color,
    required this.dateTimeStart,
  });

  factory ScheduleSummaryItemModel.fromDTO(EventSummaryItemDTO dto) {
    return ScheduleSummaryItemModel(
      color: dto.color,
      dateTimeStart: DateTime.parse(dto.dateTimeStart),
    );
  }
}
