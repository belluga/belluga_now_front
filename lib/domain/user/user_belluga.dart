import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_profile.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';

class UserBelluga extends UserContract {
  UserBelluga({
    required super.uuidValue,
    required super.profile,
    super.customData,
  });

  factory UserBelluga.fromDto(UserDto dto) {
    return UserBelluga(
      uuidValue: MongoIDValue(defaultValue: dto.id)..parse(dto.id),
      profile: UserProfile.fromDto(dto.profile),
      customData: dto.customData,
    );
  }
}
