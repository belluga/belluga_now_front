enum InviteInviterType {
  user,
  accountProfile,
}

typedef InviteInviterTypeRaw = String;

extension InviteInviterTypeApiMapper on InviteInviterType {
  String get apiValue {
    switch (this) {
      case InviteInviterType.user:
        return 'user';
      case InviteInviterType.accountProfile:
        return 'account_profile';
    }
  }

  static InviteInviterType? tryParse(InviteInviterTypeRaw? raw) {
    switch (raw?.trim().toLowerCase()) {
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
