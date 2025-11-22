import 'package:belluga_now/domain/contacts/contact_model.dart';

abstract class ContactsRepositoryContract {
  Future<bool> requestPermission();
  Future<List<ContactModel>> getContacts();
}
