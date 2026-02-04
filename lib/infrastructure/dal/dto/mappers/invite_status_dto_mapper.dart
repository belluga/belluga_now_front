import 'package:belluga_now/domain/schedule/friend_resume.dart';
import 'package:belluga_now/domain/schedule/sent_invite_status.dart';

mixin InviteStatusDtoMapper {
  EventFriendResume mapEventFriendResume(Map<String, dynamic> dto) {
    final displayName = (dto['display_name'] as String?) ??
        (dto['name'] as String?) ??
        '';
    return EventFriendResume.fromPrimitives(
      id: dto['id'] as String? ?? '',
      displayName: displayName,
      avatarUrl: dto['avatar_url'] as String?,
    );
  }

  SentInviteStatus mapSentInviteStatus(Map<String, dynamic> dto) {
    final friendMap = dto['friend'] as Map<String, dynamic>? ?? {};
    final sentAt = DateTime.parse(dto['sent_at'] as String);
    final respondedAtRaw = dto['responded_at'] as String?;
    return SentInviteStatus.fromPrimitives(
      friend: mapEventFriendResume(friendMap),
      status: dto['status'] as String? ?? '',
      sentAt: sentAt,
      respondedAt:
          respondedAtRaw != null ? DateTime.parse(respondedAtRaw) : null,
    );
  }
}
