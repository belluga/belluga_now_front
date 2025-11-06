import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_profile.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class UserBelluga extends UserContract {
  UserBelluga({
    required MongoIDValue uuidValue,
    required UserProfile profile,
    Map<String, Object?>? customData,
  }) : super(
          uuidValue: uuidValue,
          profile: profile,
          customData: customData,
        );
}
