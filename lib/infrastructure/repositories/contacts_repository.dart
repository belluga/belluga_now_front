import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsRepository implements ContactsRepositoryContract {
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
                id: c.id,
                displayName: c.displayName,
                phones: c.phones.map((p) => p.number).toList(),
                emails: c.emails.map((e) => e.address).toList(),
                avatar: c.photo,
              ))
          .toList();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError('Failed to load contacts: $error'),
        stackTrace,
      );
    }
  }
}
