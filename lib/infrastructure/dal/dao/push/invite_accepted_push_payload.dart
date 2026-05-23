class InviteAcceptedPushPayload {
  const InviteAcceptedPushPayload({
    required this.occurrenceId,
    required this.eventId,
    required this.accountProfileId,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });

  final String occurrenceId;
  final String? eventId;
  final String? accountProfileId;
  final String? userId;
  final String? displayName;
  final String? avatarUrl;
}
