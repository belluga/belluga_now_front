import 'package:belluga_now/domain/user/user_custom_data.dart';
import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/value_objects/user_identity_state_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
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

  UserBelluga toDomain() {
    return UserBelluga(
      uuidValue: MongoIDValue(defaultValue: id)..parse(id),
      profile: profile.toDomain(),
      customData: _buildCustomData(customData),
    );
  }

  UserCustomData? _buildCustomData(Map<String, dynamic>? rawCustomData) {
    if (rawCustomData == null) {
      return null;
    }
    final identityState = rawCustomData['identity_state'];
    if (identityState == null) {
      return null;
    }
    return UserCustomData(
      identityStateValue: UserIdentityStateValue.fromRaw(identityState),
    );
  }
}
