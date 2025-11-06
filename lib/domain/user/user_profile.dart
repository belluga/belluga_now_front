import 'package:belluga_now/domain/user/user_profile_contract.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class UserProfile extends UserProfileContract {
  UserProfile({
    DateTimeValue? birthdayValue,
    EmailAddressValue? emailValue,
    FullNameValue? nameValue,
    URIValue? pictureUrlValue,
  }) : super(
          birthdayValue: birthdayValue,
          emailValue: emailValue,
          nameValue: nameValue,
          pictureUrlValue: pictureUrlValue,
        );
}
