import 'package:belluga_now/domain/user/user_profile.dart';
import 'package:value_object_pattern/domain/value_objects/date_time_value.dart';
import 'package:value_object_pattern/domain/value_objects/email_address_value.dart';
import 'package:value_object_pattern/domain/value_objects/full_name_value.dart';
import 'package:value_object_pattern/domain/value_objects/uri_value.dart';

class UserProfileDto {
  final String? name;
  final String? email;
  final String? pictureUrl;
  final String? birthday;

  UserProfileDto({
    this.name,
    this.email,
    this.pictureUrl,
    this.birthday,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    return UserProfileDto(
      name: json['name'] as String?,
      email: json['email'] as String?,
      pictureUrl: json['picture_url'] as String?,
      birthday: json['birthday'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'picture_url': pictureUrl,
      'birthday': birthday,
    };
  }

  UserProfile toDomain() {
    final sanitizedName = _sanitizeFullName(name);
    return UserProfile(
      nameValue: sanitizedName != null
          ? (FullNameValue()..parse(sanitizedName))
          : null,
      emailValue: email != null ? (EmailAddressValue()..parse(email)) : null,
      pictureUrlValue:
          pictureUrl != null ? (URIValue()..parse(pictureUrl)) : null,
      birthdayValue:
          birthday != null ? (DateTimeValue()..parse(birthday)) : null,
    );
  }

  static String? _sanitizeFullName(String? rawName) {
    final trimmed = rawName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) {
      return null;
    }
    return trimmed;
  }
}
