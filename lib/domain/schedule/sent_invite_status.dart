import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/invite_status.dart';
import 'package:belluga_now/domain/schedule/value_objects/sent_invite_status_payload_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

/// Tracks status of a sent invite to a friend
class SentInviteStatus {
  SentInviteStatus({
    required this.friend,
    required this.status,
    required this.sentAtValue,
    this.respondedAtValue,
  });

  final EventFriendResume friend;
  final InviteStatus status;
  final DateTimeValue sentAtValue;
  final DateTimeValue? respondedAtValue;

  DateTime get sentAt => sentAtValue.value!;
  DateTime? get respondedAt => respondedAtValue?.value;

  SentInviteStatusPayloadValue toJson() {
    return SentInviteStatusPayloadValue({
      'friend': friend.toJson(),
      'status': status.name,
      'sent_at': sentAt.toIso8601String(),
      if (respondedAt != null) 'responded_at': respondedAt!.toIso8601String(),
    });
  }
}
