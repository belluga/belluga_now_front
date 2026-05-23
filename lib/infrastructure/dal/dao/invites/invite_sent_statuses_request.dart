class InviteSentStatusesRequest {
  const InviteSentStatusesRequest({
    required this.occurrenceId,
    this.eventId,
    this.recipientAccountProfileIds = const <String>[],
  });

  final String occurrenceId;
  final String? eventId;
  final List<String> recipientAccountProfileIds;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'occurrence_id': occurrenceId,
      if ((eventId ?? '').trim().isNotEmpty) 'event_id': eventId!.trim(),
      if (recipientAccountProfileIds.isNotEmpty)
        'recipient_account_profile_ids': recipientAccountProfileIds,
    };
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'occurrence_id': occurrenceId,
      if ((eventId ?? '').trim().isNotEmpty) 'event_id': eventId!.trim(),
      if (recipientAccountProfileIds.isNotEmpty)
        'recipient_account_profile_ids[]': recipientAccountProfileIds,
    };
  }
}
