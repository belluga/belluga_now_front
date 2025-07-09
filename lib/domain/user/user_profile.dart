import 'package:flutter_laravel_backend_boilerplate/domain/user/user_profile_contract.dart';
import 'package:flutter_laravel_backend_boilerplate/infrastructure/services/dal/dto/user_profile_dto.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class UserProfile extends UserProfileContract {


  UserProfile(
    {
      super.birthdayValue,
      super.emailValue,
      super.nameValue,
      super.pictureUrlValue,
    }
  );

  factory UserProfile.fromDTO(UserProfileDTO dto){
    return UserProfile(
      birthdayValue: DateTimeValue()..tryParse(dto.birthday),
      emailValue: EmailAddressValue()..tryParse(dto.email),
      nameValue: FullNameValue()..tryParse(dto.name),
      pictureUrlValue: URIValue()..tryParse(dto.pictureUrl)
    );
  }

}