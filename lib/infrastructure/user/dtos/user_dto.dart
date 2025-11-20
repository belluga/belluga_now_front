import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';

class UserDto {
  final String id;
  final UserProfileDto profile;
  final Map<String, dynamic>? customData;

  UserDto({
    required this.id,
    required this.profile,
    this.customData,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      profile: UserProfileDto.fromJson(json['profile'] as Map<String, dynamic>),
      customData: json['custom_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile': profile.toJson(),
      'custom_data': customData,
    };
  }
}
