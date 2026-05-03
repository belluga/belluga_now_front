import 'dart:collection';

import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/repositories/value_objects/invite_contact_region_code_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';

class InviteContacts extends IterableBase<ContactModel> {
  InviteContacts.empty({
    this.regionCodeValue,
    DomainBooleanValue? forceImportValue,
  })  : _items = const <ContactModel>[],
        forceImportValue = forceImportValue ?? _defaultForceImportValue();

  InviteContacts({
    this.regionCodeValue,
    DomainBooleanValue? forceImportValue,
  })  : _items = <ContactModel>[],
        forceImportValue = forceImportValue ?? _defaultForceImportValue();

  final List<ContactModel> _items;
  final InviteContactRegionCodeValue? regionCodeValue;
  final DomainBooleanValue forceImportValue;

  bool get forceImport => forceImportValue.value;

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

DomainBooleanValue _defaultForceImportValue() =>
    DomainBooleanValue()..parse('false');
