import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:belluga_now/infrastructure/user/dtos/user_profile_dto.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class UserProfile extends UserProfileContract {
  UserProfile({
    super.birthdayValue,
    super.emailValue,
    super.nameValue,
    super.pictureUrlValue,
  });

  factory UserProfile.fromDto(UserProfileDto dto) {
    return UserProfile(
      nameValue: dto.name != null ? (FullNameValue()..parse(dto.name!)) : null,
      emailValue:
          dto.email != null ? (EmailAddressValue()..parse(dto.email!)) : null,
      pictureUrlValue:
          dto.pictureUrl != null ? (URIValue()..parse(dto.pictureUrl!)) : null,
      birthdayValue:
          dto.birthday != null ? (DateTimeValue()..parse(dto.birthday!)) : null,
    );
  }
}
