import 'package:belluga_now/domain/partners/account_profile_model.dart';

class AccountProfileDetailState {
  const AccountProfileDetailState({
    required this.accountProfile,
  });

  static const empty = AccountProfileDetailState(accountProfile: null);

  final AccountProfileModel? accountProfile;
}
