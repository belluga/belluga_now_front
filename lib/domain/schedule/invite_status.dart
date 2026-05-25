/// Status of a sent invite
enum InviteStatus {
  /// Invite sent, awaiting response
  pending,

  /// Friend accepted and confirmed presence
  accepted,

  /// Friend declined the invite
  declined,

  /// Friend viewed but hasn't responded
  viewed,

  /// Invite expired before a response
  expired,

  /// Invite was closed because the receiver is already confirmed
  superseded,

  /// Invite was hidden by policy/governance controls
  suppressed,
}

extension InviteStatusSemantics on InviteStatus {
  bool get countsAsPendingSummary =>
      this == InviteStatus.pending || this == InviteStatus.viewed;

  bool get countsAsAcceptedSummary => this == InviteStatus.accepted;

  bool get isHiddenSentStatus =>
      this == InviteStatus.expired ||
      this == InviteStatus.superseded ||
      this == InviteStatus.suppressed;
}
