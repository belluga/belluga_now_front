import 'package:belluga_now/domain/invites/value_objects/invite_contact_hash_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_type_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_avatar_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_inviter_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_id_value.dart';

class InviteContactMatch {
  InviteContactMatch({
    required this.contactHashValue,
    required this.typeValue,
    required this.userIdValue,
    required this.displayNameValue,
    InviteInviterAvatarValue? avatarValue,
  }) : avatarValue = avatarValue ?? InviteInviterAvatarValue();

  final InviteContactHashValue contactHashValue;
  final InviteContactTypeValue typeValue;
  final UserIdValue userIdValue;
  final InviteInviterNameValue displayNameValue;
  final InviteInviterAvatarValue avatarValue;

  String get contactHash => contactHashValue.value;
  String get type => typeValue.value;
  String get userId => userIdValue.value;
  String get displayName => displayNameValue.value;
  String? get avatarUrl => avatarValue.value?.toString();
}
