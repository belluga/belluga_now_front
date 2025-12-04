import 'package:belluga_now/domain/user/user_belluga.dart';
import 'package:belluga_now/domain/user/user_profile.dart';
import 'package:belluga_now/infrastructure/dal/dto/user_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/user_profile_dto.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/mongo_id_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

mixin UserDtoMapper {
  UserBelluga mapUser(UserDTO dto) {
    return UserBelluga(
      uuidValue: MongoIDValue()..parse(dto.id),
      profile: mapUserProfile(dto.profile),
      customData: dto.customData,
    );
  }

  UserProfile mapUserProfile(UserProfileDTO dto) {
    return UserProfile(
      birthdayValue: DateTimeValue()..tryParse(dto.birthday),
      emailValue: EmailAddressValue()..tryParse(dto.email),
      nameValue: FullNameValue()..tryParse(dto.name),
      pictureUrlValue: URIValue()..tryParse(dto.pictureUrl),
    );
  }
}
