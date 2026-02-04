import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_profile.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class UserBelluga extends UserContract {
  UserBelluga({
    required super.uuidValue,
    required super.profile,
    super.customData,
  });

  factory UserBelluga.fromPrimitives({
    required String id,
    required UserProfile profile,
    Map<String, Object?>? customData,
  }) {
    return UserBelluga(
      uuidValue: MongoIDValue(defaultValue: id)..parse(id),
      profile: profile,
      customData: customData,
    );
  }
}
