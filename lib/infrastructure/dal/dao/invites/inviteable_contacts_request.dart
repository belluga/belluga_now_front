class InviteableContactsRequest {
  const InviteableContactsRequest({
    required this.occurrenceId,
    this.eventId,
    this.page = 1,
    this.pageSize = 100,
  });

  final String occurrenceId;
  final String? eventId;
  final int page;
  final int pageSize;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'occurrence_id': occurrenceId,
      if ((eventId ?? '').trim().isNotEmpty) 'event_id': eventId!.trim(),
      'page': page,
      'page_size': pageSize,
    };
  }

  Map<String, dynamic> toQueryParameters() => toJson();
}
