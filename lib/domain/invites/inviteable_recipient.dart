import 'package:belluga_now/domain/invites/projections/friend_resume.dart';
import 'package:belluga_now/domain/invites/inviteable_reasons.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_profile_exposure_level_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

class InviteableRecipient {
  InviteableRecipient({
    required this.userIdValue,
    required this.receiverAccountProfileIdValue,
    required this.displayNameValue,
    InviteInviterAvatarValue? avatarValue,
    InviteProfileExposureLevelValue? profileExposureLevelValue,
    InviteableReasons? inviteableReasons,
    DomainBooleanValue? isInviteableValue,
  })  : avatarValue = avatarValue ?? InviteInviterAvatarValue(),
        profileExposureLevelValue =
            profileExposureLevelValue ?? InviteProfileExposureLevelValue(),
        inviteableReasons = inviteableReasons ?? InviteableReasons(),
        isInviteableValue = isInviteableValue ?? DomainBooleanValue();

  final UserIdValue userIdValue;
  final InviteAccountProfileIdValue receiverAccountProfileIdValue;
  final InviteInviterNameValue displayNameValue;
  final InviteInviterAvatarValue avatarValue;
  final InviteProfileExposureLevelValue profileExposureLevelValue;
  final InviteableReasons inviteableReasons;
  final DomainBooleanValue isInviteableValue;

  String get userId => userIdValue.value;
  String get receiverAccountProfileId => receiverAccountProfileIdValue.value;
  String get displayName => displayNameValue.value;
  String? get avatarUrl => avatarValue.value?.toString();
  String get profileExposureLevel => profileExposureLevelValue.value;
  bool get isInviteable => isInviteableValue.value;
  bool get isFriend => inviteableReasons.contains('friend');

  InviteFriendResume toFriendResume() {
    final friendAvatarValue = FriendAvatarValue();
    final normalizedAvatar = avatarUrl?.trim();
    if (normalizedAvatar != null && normalizedAvatar.isNotEmpty) {
      friendAvatarValue.parse(normalizedAvatar);
    }

    return InviteFriendResume(
      idValue: FriendIdValue()..parse(userId),
      accountProfileIdValue: receiverAccountProfileIdValue,
      nameValue: TitleValue()..parse(displayName),
      avatarValue: friendAvatarValue,
      matchLabelValue: FriendMatchLabelValue()..parse(matchLabel),
      inviteableReasons: inviteableReasons,
      profileExposureLevelValue: profileExposureLevelValue,
    );
  }

  String get matchLabel {
    if (inviteableReasons.contains('friend')) {
      return 'Amigo no Belluga';
    }
    if (inviteableReasons.contains('favorite_by_you')) {
      return 'Favorito no Belluga';
    }
    if (inviteableReasons.contains('favorited_you')) {
      return 'Favoritou você';
    }
    if (inviteableReasons.contains('contact_match')) {
      return 'Contato no Belluga';
    }
    return 'Disponível para convidar';
  }
}
