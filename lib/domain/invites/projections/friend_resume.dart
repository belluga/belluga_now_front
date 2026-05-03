import 'package:belluga_now/domain/invites/inviteable_reasons.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_profile_exposure_level_value.dart';
import 'package:belluga_now/domain/user/friend.dart';
import 'package:belluga_now/domain/user/value_objects/friend_avatar_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_id_value.dart';
import 'package:belluga_now/domain/user/value_objects/friend_match_label_value.dart';
import 'package:belluga_now/domain/value_objects/title_value.dart';

/// Lightweight friend projection for invite sharing and friend selection
class InviteFriendResume {
  InviteFriendResume({
    required this.idValue,
    required this.nameValue,
    required this.avatarValue,
    required this.matchLabelValue,
    InviteAccountProfileIdValue? accountProfileIdValue,
    InviteableReasons? inviteableReasons,
    InviteProfileExposureLevelValue? profileExposureLevelValue,
  })  : accountProfileIdValue =
            accountProfileIdValue ?? InviteAccountProfileIdValue(),
        inviteableReasons = inviteableReasons ?? InviteableReasons(),
        profileExposureLevelValue =
            profileExposureLevelValue ?? InviteProfileExposureLevelValue();

  final FriendIdValue idValue;
  final InviteAccountProfileIdValue accountProfileIdValue;
  final TitleValue nameValue;
  final FriendAvatarValue avatarValue;
  final FriendMatchLabelValue matchLabelValue;
  final InviteableReasons inviteableReasons;
  final InviteProfileExposureLevelValue profileExposureLevelValue;

  String get id => idValue.value;
  String get accountProfileId => accountProfileIdValue.value;
  String get profileExposureLevel => profileExposureLevelValue.value;

  String get name => nameValue.value;
  Uri get avatarUri {
    final uri = avatarValue.value;
    if (uri == null) {
      throw StateError('Friend avatar must not be null');
    }
    return uri;
  }

  String get matchLabel => matchLabelValue.value;

  factory InviteFriendResume.fromFriend(Friend friend) {
    return InviteFriendResume(
      idValue: friend.idValue,
      nameValue: friend.nameValue,
      avatarValue: friend.avatarValue,
      matchLabelValue: friend.matchLabelValue,
    );
  }
}
