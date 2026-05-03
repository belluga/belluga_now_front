import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_hash_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_type_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/invites/inviteable_reasons.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_profile_exposure_level_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class InviteContactMatch {
  InviteContactMatch({
    required this.contactHashValue,
    required this.typeValue,
    required this.userIdValue,
    required this.displayNameValue,
    InviteAccountProfileIdValue? receiverAccountProfileIdValue,
    InviteInviterAvatarValue? avatarValue,
    InviteProfileExposureLevelValue? profileExposureLevelValue,
    InviteableReasons? inviteableReasons,
    DomainBooleanValue? isInviteableValue,
  })  : receiverAccountProfileIdValue =
            receiverAccountProfileIdValue ?? InviteAccountProfileIdValue(),
        avatarValue = avatarValue ?? InviteInviterAvatarValue(),
        profileExposureLevelValue =
            profileExposureLevelValue ?? InviteProfileExposureLevelValue(),
        inviteableReasons = inviteableReasons ?? InviteableReasons(),
        isInviteableValue = isInviteableValue ?? DomainBooleanValue();

  final InviteContactHashValue contactHashValue;
  final InviteContactTypeValue typeValue;
  final UserIdValue userIdValue;
  final InviteAccountProfileIdValue receiverAccountProfileIdValue;
  final InviteInviterNameValue displayNameValue;
  final InviteInviterAvatarValue avatarValue;
  final InviteProfileExposureLevelValue profileExposureLevelValue;
  final InviteableReasons inviteableReasons;
  final DomainBooleanValue isInviteableValue;

  String get contactHash => contactHashValue.value;
  String get type => typeValue.value;
  String get userId => userIdValue.value;
  String get receiverAccountProfileId => receiverAccountProfileIdValue.value;
  String get displayName => displayNameValue.value;
  String? get avatarUrl => avatarValue.value?.toString();
  String get profileExposureLevel => profileExposureLevelValue.value;
  bool get isInviteable => isInviteableValue.value;
}
