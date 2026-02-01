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

  final EventFriendResume friend;
  final InviteStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  factory SentInviteStatus.fromPrimitives({
    required EventFriendResume friend,
    required String status,
    required DateTime sentAt,
    DateTime? respondedAt,
  }) {
    return SentInviteStatus(
      friend: friend,
      status: _parseStatus(status),
      sentAt: sentAt,
      respondedAt: respondedAt,
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
