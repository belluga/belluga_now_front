import 'dart:collection';

import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/schedule/event_linked_account_profile_taxonomy_term.dart';

class EventLinkedAccountProfileTaxonomyTerms
    extends IterableBase<EventLinkedAccountProfileTaxonomyTerm> {
  const EventLinkedAccountProfileTaxonomyTerms.empty()
      : _items = const <EventLinkedAccountProfileTaxonomyTerm>[];

  EventLinkedAccountProfileTaxonomyTerms()
      : _items = <EventLinkedAccountProfileTaxonomyTerm>[];

  final List<EventLinkedAccountProfileTaxonomyTerm> _items;

  void addTerm({
    required AccountProfileTagValue typeValue,
    required AccountProfileTagValue valueValue,
    required AccountProfileTagValue nameValue,
    AccountProfileTagValue? taxonomyNameValue,
    AccountProfileTagValue? labelValue,
  }) {
    _items.add(
      EventLinkedAccountProfileTaxonomyTerm(
        typeValue: typeValue,
        valueValue: valueValue,
        nameValue: nameValue,
        taxonomyNameValue: taxonomyNameValue,
        compatibilityLabelValue: labelValue,
      ),
    );
  }

  List<EventLinkedAccountProfileTaxonomyTerm> get items =>
      List<EventLinkedAccountProfileTaxonomyTerm>.unmodifiable(_items);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  int get length => _items.length;

  @override
  Iterator<EventLinkedAccountProfileTaxonomyTerm> get iterator =>
      _items.iterator;
}
