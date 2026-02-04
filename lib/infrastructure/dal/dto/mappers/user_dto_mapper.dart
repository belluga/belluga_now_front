import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/user_profile.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_dto.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';

mixin UserDtoMapper {
  UserBelluga mapUserDto(UserDto dto) {
    return UserBelluga.fromPrimitives(
      id: dto.id,
      profile: mapUserProfileDto(dto.profile),
      customData: dto.customData,
    );
  }

  UserProfile mapUserProfileDto(UserProfileDto dto) {
    return UserProfile.fromPrimitives(
      name: dto.name,
      email: dto.email,
      pictureUrl: dto.pictureUrl,
      birthday: dto.birthday,
    );
  }
}
