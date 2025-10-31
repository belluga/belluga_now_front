class EventSummaryItemDTO {
  const EventSummaryItemDTO({
    required this.dateTimeStart,
    this.color,
  });

  final String dateTimeStart;
  final String? color;
}
