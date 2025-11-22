import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';

/// Wrapper class that combines a friend with their invite status for a specific event
class InviteFriendResumeWithStatus {
  const InviteFriendResumeWithStatus({
    required this.friend,
    this.inviteStatus,
  });

  final InviteFriendResume friend;
  final InviteStatus? inviteStatus; // null = not invited yet

  /// Whether this friend has been invited to the event
  bool get isInvited => inviteStatus != null;

  /// Whether the friend has accepted the invite
  bool get isAccepted => inviteStatus == InviteStatus.accepted;

  /// Whether the invite is still pending
  bool get isPending => inviteStatus == InviteStatus.pending;

  /// Whether the friend has declined the invite
  bool get isDeclined => inviteStatus == InviteStatus.declined;

  /// Whether the friend has viewed the invite
  bool get isViewed => inviteStatus == InviteStatus.viewed;

  /// Get a user-friendly status label
  String get statusLabel {
    if (inviteStatus == null) return '';
    switch (inviteStatus!) {
      case InviteStatus.pending:
        return 'Já convidado';
      case InviteStatus.accepted:
        return 'Convite aceito';
      case InviteStatus.declined:
        return 'Convite recusado';
      case InviteStatus.viewed:
        return 'Visualizado';
    }
  }
}
