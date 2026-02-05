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
    final sanitizedName = _sanitizeFullName(dto.name);
    return UserProfile.fromPrimitives(
      name: sanitizedName,
      email: dto.email,
      pictureUrl: dto.pictureUrl,
      birthday: dto.birthday,
    );
  }

  String? _sanitizeFullName(String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return null;
    }
    return trimmed;
  }
}
