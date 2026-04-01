import 'dart:collection';

import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';

class TenantAdminTaxonomyTerms extends IterableBase<TenantAdminTaxonomyTerm> {
  const TenantAdminTaxonomyTerms.empty()
      : _items = const <TenantAdminTaxonomyTerm>[];

  TenantAdminTaxonomyTerms() : _items = <TenantAdminTaxonomyTerm>[];

  final List<TenantAdminTaxonomyTerm> _items;

  void add(TenantAdminTaxonomyTerm item) {
    _items.add(item);
  }

  List<TenantAdminTaxonomyTerm> get items =>
      List<TenantAdminTaxonomyTerm>.unmodifiable(_items);
  @override
  bool get isEmpty => _items.isEmpty;
  @override
  bool get isNotEmpty => _items.isNotEmpty;
  @override
  int get length => _items.length;

  @override
  Iterator<TenantAdminTaxonomyTerm> get iterator => _items.iterator;
}
