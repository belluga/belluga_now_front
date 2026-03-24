import 'package:equatable/equatable.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_avatar_bytes_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_display_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_id_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_string_list_value.dart';

class ContactModel extends Equatable {
  ContactModel({
    required this.idValue,
    required this.displayNameValue,
    ContactStringListValue? phoneValues,
    ContactStringListValue? emailValues,
    ContactAvatarBytesValue? avatarValue,
  })  : phoneValues = phoneValues ?? ContactStringListValue(),
        emailValues = emailValues ?? ContactStringListValue(),
        avatarValue = avatarValue ?? ContactAvatarBytesValue();

  final ContactIdValue idValue;
  final ContactDisplayNameValue displayNameValue;
  final ContactStringListValue phoneValues;
  final ContactStringListValue emailValues;
  final ContactAvatarBytesValue avatarValue;

  String get id => idValue.value;
  String get displayName => displayNameValue.value;
  List<String> get phones => phoneValues.value;
  List<String> get emails => emailValues.value;
  List<int>? get avatar => avatarValue.value;

  @override
  List<Object?> get props => [id, displayName, phones, emails, avatar];
}
