import 'package:equatable/equatable.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_avatar_bytes_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_display_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_email_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_id_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_phone_value.dart';

class ContactModel extends Equatable {
  ContactModel({
    required this.idValue,
    required this.displayNameValue,
    List<ContactPhoneValue>? phoneValues,
    List<ContactEmailValue>? emailValues,
    ContactAvatarBytesValue? avatarValue,
  })  : phoneValues = List<ContactPhoneValue>.unmodifiable(
          phoneValues ?? const <ContactPhoneValue>[],
        ),
        emailValues = List<ContactEmailValue>.unmodifiable(
          emailValues ?? const <ContactEmailValue>[],
        ),
        avatarValue = avatarValue ?? ContactAvatarBytesValue();

  final ContactIdValue idValue;
  final ContactDisplayNameValue displayNameValue;
  final List<ContactPhoneValue> phoneValues;
  final List<ContactEmailValue> emailValues;
  final ContactAvatarBytesValue avatarValue;

  String get id => idValue.value;
  String get displayName => displayNameValue.value;
  List<ContactPhoneValue> get phones =>
      List<ContactPhoneValue>.unmodifiable(phoneValues);
  List<ContactEmailValue> get emails =>
      List<ContactEmailValue>.unmodifiable(emailValues);
  ContactAvatarBytesValue get avatar => avatarValue;

  @override
  List<Object?> get props => [id, displayName, phones, emails, avatar];
}
