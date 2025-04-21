import 'package:flutter_laravel_backend_boilerplate/application/configurations/user_dto_labels.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/user_profile_dto.dart';

class UserDTO {
  final String id;
  final UserProfileDTO profile;
  final Map<String,Object?>? customData;

  UserDTO({
    required this.id,
    required this.profile,
    this.customData,
  });

  factory UserDTO.fromMap(Map<String, Object?> map) {

    print("map");
    print(map);

    return UserDTO(
      id: map[UserDtoLabels.id] as String,
      profile: UserProfileDTO.fromMap( map[UserDtoLabels.profile]  as Map<String, Object?>),
      customData: map[UserDtoLabels.customData] as Map<String, Object?>?,
    );
  }
}
