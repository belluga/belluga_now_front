import 'dart:collection';

import 'package:belluga_now/domain/partners/value_objects/account_profile_tag_value.dart';
import 'package:belluga_now/domain/partners/account_profile_taxonomy_term.dart';

class AccountProfileTaxonomyTerms
    extends IterableBase<AccountProfileTaxonomyTerm> {
  const AccountProfileTaxonomyTerms.empty()
    : _items = const <AccountProfileTaxonomyTerm>[];

  AccountProfileTaxonomyTerms() : _items = <AccountProfileTaxonomyTerm>[];

  final List<AccountProfileTaxonomyTerm> _items;

  void addTerm({
    required AccountProfileTagValue typeValue,
    required AccountProfileTagValue valueValue,
    required AccountProfileTagValue nameValue,
    AccountProfileTagValue? taxonomyNameValue,
    AccountProfileTagValue? labelValue,
  }) {
    _items.add(
      AccountProfileTaxonomyTerm(
        typeValue: typeValue,
        valueValue: valueValue,
        nameValue: nameValue,
        taxonomyNameValue: taxonomyNameValue,
        compatibilityLabelValue: labelValue,
      ),
    );
  }

  List<AccountProfileTaxonomyTerm> get items =>
      List<AccountProfileTaxonomyTerm>.unmodifiable(_items);

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  int get length => _items.length;

  @override
  Iterator<AccountProfileTaxonomyTerm> get iterator => _items.iterator;
}
