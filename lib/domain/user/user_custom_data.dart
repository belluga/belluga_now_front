import 'package:belluga_now/domain/user/value_objects/user_identity_state_value.dart';

class UserCustomData {
  const UserCustomData({
    this.identityStateValue,
  });

  final UserIdentityStateValue? identityStateValue;

  bool get isAnonymous => identityStateValue?.isAnonymous ?? false;
}
