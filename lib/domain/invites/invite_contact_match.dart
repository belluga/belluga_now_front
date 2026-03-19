class InviteContactMatch {
  const InviteContactMatch({
    required this.contactHash,
    required this.type,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String contactHash;
  final String type;
  final String userId;
  final String displayName;
  final String? avatarUrl;
}
