import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

typedef UserContractPrimString = String;
typedef UserContractPrimInt = int;
typedef UserContractPrimBool = bool;
typedef UserContractPrimDouble = double;
typedef UserContractPrimDateTime = DateTime;
typedef UserContractPrimDynamic = dynamic;

abstract class UserContract {
  final MongoIDValue uuidValue;
  final UserProfileContract profile;
  Map<UserContractPrimString, Object?>? customData;

  UserContract({
    required this.uuidValue,
    required this.profile,
    this.customData,
  });

  Future<void> updateCustomData(
      Map<UserContractPrimString, Object?> newCustomData) {
    customData = newCustomData;

    return Future.value();
  }
}
