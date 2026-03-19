class InviteShareCodeResult {
  const InviteShareCodeResult({
    required this.code,
    required this.eventId,
    this.occurrenceId,
  });

  final String code;
  final String eventId;
  final String? occurrenceId;
}
