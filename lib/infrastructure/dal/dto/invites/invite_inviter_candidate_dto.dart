class InviteInviterCandidateDto {
  const InviteInviterCandidateDto({
    required this.inviteId,
    required this.displayName,
    required this.avatarUrl,
    required this.status,
    this.principalKind,
    this.principalId,
  });

  final String inviteId;
  final String displayName;
  final String? avatarUrl;
  final String status;
  final String? principalKind;
  final String? principalId;

  factory InviteInviterCandidateDto.fromJson(Map<String, dynamic> json) {
    final inviterPrincipal = json['inviter_principal'];
    final inviterPrincipalMap =
        inviterPrincipal is Map<String, dynamic> ? inviterPrincipal : null;

    return InviteInviterCandidateDto(
      inviteId: (json['invite_id'] ?? json['id'] ?? '').toString(),
      displayName:
          (json['display_name'] ?? json['inviter_name'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      status: (json['status'] ?? 'pending').toString(),
      principalKind: inviterPrincipalMap?['kind']?.toString(),
      principalId: inviterPrincipalMap?['id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'invite_id': inviteId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'status': status,
      if (principalKind != null || principalId != null)
        'inviter_principal': {
          'kind': principalKind,
          'id': principalId,
        },
    };
  }
}
