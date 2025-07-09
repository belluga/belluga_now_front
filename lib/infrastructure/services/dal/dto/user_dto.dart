import 'package:unifast_portal/application/configurations/user_dto_labels.dart';
import 'package:unifast_portal/infrastructure/services/dal/dto/user_profile_dto.dart';

class UserDTO {
  final String id;
  final UserProfileDTO profile;
  final Map<String, Object?>? customData;

  UserDTO({required this.id, required this.profile, this.customData});

  factory UserDTO.fromJson(Map<String, Object?> map) {
    return UserDTO(
      id: map[UserDtoLabels.id] as String,
      profile: UserProfileDTO.fromJson(
        map[UserDtoLabels.profile] as Map<String, Object?>,
      ),
      customData: map[UserDtoLabels.customData] as Map<String, Object?>?,
    );
  }
}
