import 'package:belluga_now/domain/invites/invite_account_profile_ids.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_account_profile_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_id_value.dart';
import 'package:belluga_now/domain/invites/value_objects/invite_contact_group_name_value.dart';

class InviteContactGroup {
  InviteContactGroup({
    required this.idValue,
    required this.nameValue,
    InviteAccountProfileIds? recipientAccountProfileIds,
  }) : recipientAccountProfileIds =
            recipientAccountProfileIds ?? InviteAccountProfileIds();

  final InviteContactGroupIdValue idValue;
  final InviteContactGroupNameValue nameValue;
  final InviteAccountProfileIds recipientAccountProfileIds;

  String get id => idValue.value;
  String get name => nameValue.value;

  int get recipientCount => recipientAccountProfileIds.length;

  bool containsProfile(InviteAccountProfileIdValue accountProfileIdValue) {
    return recipientAccountProfileIds.contains(accountProfileIdValue.value);
  }
}
