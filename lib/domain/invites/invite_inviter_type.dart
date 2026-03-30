import 'package:belluga_now/domain/invites/value_objects/invite_inviter_type_raw_value.dart';

enum InviteInviterType {
  user,
  accountProfile,
}

extension InviteInviterTypeApiMapper on InviteInviterType {
  String get apiValue {
    switch (this) {
      case InviteInviterType.user:
        return 'user';
      case InviteInviterType.accountProfile:
        return 'account_profile';
    }
  }

  static InviteInviterType? tryParse(InviteInviterTypeRawValue? raw) {
    switch (raw?.value.trim().toLowerCase()) {
      case 'user':
        return InviteInviterType.user;
      case 'account_profile':
      case 'partner':
        return InviteInviterType.accountProfile;
      default:
        return null;
    }
  }
}
