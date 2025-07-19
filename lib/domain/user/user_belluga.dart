import 'package:unifast_portal/domain/user/user_contract.dart';
import 'package:unifast_portal/domain/user/user_profile.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/user_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class UserBelluga extends UserContract {
  UserBelluga({
    required super.uuidValue,
    required super.profile,
    super.customData,
  });

  factory UserBelluga.fromDTO(UserDTO user) {
    return UserBelluga(
      uuidValue: MongoIDValue()..parse(user.id),
      profile: UserProfile.fromDTO(user.profile),
      customData: user.customData,
    );
  }
}
