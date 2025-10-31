import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';

class UserProfileContract {
  final FullNameValue? nameValue;
  final EmailAddressValue? emailValue;
  final URIValue? pictureUrlValue;
  final DateTimeValue? birthdayValue;

  UserProfileContract({
    this.birthdayValue,
    this.emailValue,
    this.nameValue,
    this.pictureUrlValue,
  });
}
