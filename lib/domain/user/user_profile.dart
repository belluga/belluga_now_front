import 'package:belluga_now/domain/user/user_profile_contract.dart';
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

  factory UserProfile.fromPrimitives({
    String? name,
    String? email,
    String? pictureUrl,
    String? birthday,
  }) {
    return UserProfile(
      nameValue: name != null ? (FullNameValue()..parse(name)) : null,
      emailValue: email != null ? (EmailAddressValue()..parse(email)) : null,
      pictureUrlValue:
          pictureUrl != null ? (URIValue()..parse(pictureUrl)) : null,
      birthdayValue:
          birthday != null ? (DateTimeValue()..parse(birthday)) : null,
    );
  }
}
