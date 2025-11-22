import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsRepository implements ContactsRepositoryContract {
  @override
  Future<bool> requestPermission() async {
    return await FlutterContacts.requestPermission();
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      return [];
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
  }
}
