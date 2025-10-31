class EventActionsDTO {
  const EventActionsDTO({
    this.id,
    required this.label,
    this.color,
    required this.openIn,
    this.itemType,
    this.itemId,
    this.externalUrl,
  });

  final String? id;
  final String label;
  final String? color;
  final String openIn;
  final String? itemType;
  final String? itemId;
  final String? externalUrl;
}
