class InviteSentSummaryRequest {
  const InviteSentSummaryRequest({
    required this.occurrenceId,
    this.eventId,
    this.previewLimit = 5,
  });

  final String occurrenceId;
  final String? eventId;
  final int previewLimit;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'occurrence_id': occurrenceId,
      if ((eventId ?? '').trim().isNotEmpty) 'event_id': eventId!.trim(),
      'preview_limit': previewLimit,
    };
  }

  Map<String, dynamic> toQueryParameters() => toJson();
}
