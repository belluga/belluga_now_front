class InviteTargetRefRequest {
  const InviteTargetRefRequest({
    required this.eventId,
    required this.occurrenceId,
  });

  final String eventId;
  final String occurrenceId;

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'occurrence_id': occurrenceId,
    };
  }
}
