import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';

class MockContactsRepository implements ContactsRepositoryContract {
  @override
  Future<bool> requestPermission() async {
    // Simulate permission granted
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return [
      const ContactModel(
        id: '1',
        displayName: 'Alice Smith',
        phones: ['+1 555-0100'],
        emails: ['alice@example.com'],
      ),
      const ContactModel(
        id: '2',
        displayName: 'Bob Jones',
        phones: ['+1 555-0101'],
      ),
      const ContactModel(
        id: '3',
        displayName: 'Charlie Brown',
        phones: ['+1 555-0102'],
        emails: ['charlie@example.com'],
      ),
      const ContactModel(
        id: '4',
        displayName: 'David Wilson',
        phones: ['+1 555-0103'],
      ),
      const ContactModel(
        id: '5',
        displayName: 'Eva Green',
        phones: ['+1 555-0104'],
        emails: ['eva@example.com'],
      ),
    ];
  }
}
