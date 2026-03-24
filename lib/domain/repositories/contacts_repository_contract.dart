import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class ContactsRepositoryContract {
  final contactsStreamValue =
      StreamValue<List<ContactModel>?>(defaultValue: null);

  Future<bool> requestPermission();
  Future<List<ContactModel>> getContacts();

  Future<void> initializeContacts() async {
    await refreshContacts();
  }

  Future<void> refreshContacts() async {
    final contacts = await getContacts();
    contactsStreamValue.addValue(contacts);
  }
}
