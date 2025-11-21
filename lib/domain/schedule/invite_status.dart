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
}
