import 'package:belluga_now/domain/contacts/contact_model.dart';

abstract class ContactsLocalCacheContract {
  Future<List<ContactModel>?> read();
  Future<void> write(List<ContactModel> contacts);
}
