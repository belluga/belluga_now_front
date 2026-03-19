class InviteDeclineResult {
  const InviteDeclineResult({
    required this.inviteId,
    required this.status,
    required this.groupHasOtherPending,
    this.declinedAt,
  });

  final String inviteId;
  final String status;
  final bool groupHasOtherPending;
  final DateTime? declinedAt;

  bool get isDeclined => status == 'declined' || status == 'already_declined';
}
