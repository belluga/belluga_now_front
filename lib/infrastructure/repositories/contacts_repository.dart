import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_avatar_bytes_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_display_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_email_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_id_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_phone_value.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stream_value/core/stream_value.dart';

class ContactsRepository implements ContactsRepositoryContract {
  @override
  final contactsStreamValue =
      StreamValue<List<ContactModel>?>(defaultValue: null);

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return false;
    }

    try {
      final status = await Permission.contacts.request();
      return status.isGranted;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError('Failed to request contacts permission: $error'),
        stackTrace,
      );
    }
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    if (kIsWeb) {
      return const [];
    }

    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        return const [];
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      return contacts
          .map((c) => ContactModel(
                idValue: ContactIdValue(c.id),
                displayNameValue: ContactDisplayNameValue(c.displayName),
                phoneValues: c.phones
                    .map((phone) => ContactPhoneValue(raw: phone.number))
                    .toList(growable: false),
                emailValues: c.emails
                    .map((email) => ContactEmailValue(raw: email.address))
                    .toList(growable: false),
                avatarValue: ContactAvatarBytesValue(c.photo),
              ))
          .toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError('Failed to load contacts: $error'),
        stackTrace,
      );
    }
  }

  @override
  Future<void> initializeContacts() async {
    await refreshContacts();
  }

  @override
  Future<void> refreshContacts() async {
    final contacts = await getContacts();
    contactsStreamValue.addValue(contacts);
  }
}
