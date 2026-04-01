import 'package:belluga_now/domain/user/user_custom_data.dart';
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
  UserCustomData? customData;

  UserContract({
    required this.uuidValue,
    required this.profile,
    this.customData,
  });

  Future<void> updateCustomData(UserCustomData newCustomData) {
    customData = newCustomData;

    return Future.value();
  }
}
