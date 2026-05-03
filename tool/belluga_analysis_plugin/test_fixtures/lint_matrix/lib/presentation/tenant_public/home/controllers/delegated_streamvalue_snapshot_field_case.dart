// ignore_for_file: unused_element

import '../../../../domain/contacts/contact_model.dart';

class StreamValue<T> {
  const StreamValue({this.value});

  final T? value;
}

abstract class _ContactsRepositoryContract {
  StreamValue<List<ContactModel>?> get contactsStreamValue;
}

class _ContactsRepository implements _ContactsRepositoryContract {
  @override
  final StreamValue<List<ContactModel>?> contactsStreamValue =
      const StreamValue<List<ContactModel>?>(value: <ContactModel>[]);
}

class _DelegatedStreamValueSnapshotFieldCaseController {
  final _contactsRepository = _ContactsRepository();

  List<ContactModel> _cachedContacts = const <ContactModel>[];

  void hydrate() {
    // expect_lint: controller_delegated_streamvalue_snapshot_field_forbidden
    _cachedContacts =
        _contactsRepository.contactsStreamValue.value ?? const <ContactModel>[];
  }
}
