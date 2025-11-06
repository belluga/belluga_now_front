import 'package:belluga_now/domain/user/user_contract.dart';
class UserBelluga extends UserContract {
  UserBelluga({
    required super.uuidValue,
    required super.profile,
    super.customData,
  });
}
