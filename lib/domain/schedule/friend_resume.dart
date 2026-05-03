import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/schedule/value_objects/event_friend_resume_payload_value.dart';

/// Lightweight friend projection for event social proof and invite tracking
class EventFriendResume {
  EventFriendResume({
    required this.idValue,
    required this.displayNameValue,
    required this.avatarUrlValue,
    InviteAccountProfileIdValue? accountProfileIdValue,
  }) : accountProfileIdValue =
            accountProfileIdValue ?? InviteAccountProfileIdValue();

  final UserIdValue idValue;
  final InviteAccountProfileIdValue accountProfileIdValue;
  final UserDisplayNameValue displayNameValue;
  final UserAvatarValue avatarUrlValue;

  String get id => idValue.value;
  String get accountProfileId => accountProfileIdValue.value;
  String get displayName => displayNameValue.value;
  String? get avatarUrl => avatarUrlValue.value?.toString();

  EventFriendResumePayloadValue toJson() {
    return EventFriendResumePayloadValue({
      'id': id,
      if (accountProfileId.isNotEmpty) 'account_profile_id': accountProfileId,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    });
  }
}
