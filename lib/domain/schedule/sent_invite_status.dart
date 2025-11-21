import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';

/// Tracks status of a sent invite to a friend
class SentInviteStatus {
  SentInviteStatus({
    required this.friend,
    required this.status,
    required this.sentAt,
    this.respondedAt,
  });

  final FriendResume friend;
  final InviteStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  /// Create from DTO
  factory SentInviteStatus.fromDto(Map<String, dynamic> json) {
    return SentInviteStatus(
      friend: FriendResume.fromDto(json['friend'] as Map<String, dynamic>),
      status: _parseStatus(json['status'] as String?),
      sentAt: DateTime.parse(json['sent_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  static InviteStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return InviteStatus.accepted;
      case 'declined':
        return InviteStatus.declined;
      case 'viewed':
        return InviteStatus.viewed;
      default:
        return InviteStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'friend': friend.toJson(),
      'status': status.name,
      'sent_at': sentAt.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
    };
  }
}
