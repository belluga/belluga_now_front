import 'dart:collection';

import 'package:belluga_now/domain/contacts/contact_model.dart';

class InviteContacts extends IterableBase<ContactModel> {
  const InviteContacts.empty() : _items = const <ContactModel>[];

  InviteContacts() : _items = <ContactModel>[];

  final List<ContactModel> _items;

  void add(ContactModel item) {
    _items.add(item);
  }

  List<ContactModel> get items => List<ContactModel>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  @override
  Iterator<ContactModel> get iterator => _items.iterator;
}
