import 'package:unifast_portal/application/configurations/user_dto_labels.dart';

class UserProfileDTO {
  final String? birthday;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? gender;
  final String? name;
  final String? pictureUrl;

  UserProfileDTO({
    required this.birthday,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.name,
    required this.pictureUrl,
  });

  factory UserProfileDTO.fromJson(Map<String, Object?> map) {
    return UserProfileDTO(
      birthday: map[UserDtoLabels.profileLabels.birthday] as String?,
      email: map[UserDtoLabels.profileLabels.email] as String?,
      firstName: map[UserDtoLabels.profileLabels.firstName] as String?,
      gender: map[UserDtoLabels.profileLabels.gender] as String?,
      lastName: map[UserDtoLabels.profileLabels.lastName] as String?,
      name: map[UserDtoLabels.profileLabels.name] as String?,
      pictureUrl: map[UserDtoLabels.profileLabels.pictureUrl] as String?,
    );
  }
}
