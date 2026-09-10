import 'package:belluga_now/domain/partners/account_profile_complete.dart';

class AccountProfileDetailState {
  const AccountProfileDetailState({required this.accountProfile});

  static const empty = AccountProfileDetailState(accountProfile: null);

  final AccountProfileComplete? accountProfile;
}
