import 'dart:collection';

import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/repositories/value_objects/invite_contact_region_code_value.dart';

class InviteContacts extends IterableBase<ContactModel> {
  const InviteContacts.empty({this.regionCodeValue})
      : _items = const <ContactModel>[];

  InviteContacts({this.regionCodeValue}) : _items = <ContactModel>[];

  final List<ContactModel> _items;
  final InviteContactRegionCodeValue? regionCodeValue;

  String? get regionCode {
    final value = regionCodeValue?.value.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  void add(ContactModel item) {
    _items.add(item);
  }

  List<ContactModel> get items => List<ContactModel>.unmodifiable(_items);
  @override
  bool get isEmpty => _items.isEmpty;
  @override
  bool get isNotEmpty => _items.isNotEmpty;
  @override
  int get length => _items.length;

  @override
  Iterator<ContactModel> get iterator => _items.iterator;
}
