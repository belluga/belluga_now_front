import 'dart:collection';

import 'package:belluga_now/domain/repositories/schedule_repository_contract_taxonomy_entry.dart';

class ScheduleTaxonomyEntries
    extends IterableBase<ScheduleRepositoryContractTaxonomyEntry> {
  const ScheduleTaxonomyEntries.empty()
      : _items = const <ScheduleRepositoryContractTaxonomyEntry>[];

  ScheduleTaxonomyEntries()
      : _items = <ScheduleRepositoryContractTaxonomyEntry>[];

  final List<ScheduleRepositoryContractTaxonomyEntry> _items;

  void add(ScheduleRepositoryContractTaxonomyEntry item) {
    _items.add(item);
  }

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  @override
  Iterator<ScheduleRepositoryContractTaxonomyEntry> get iterator =>
      _items.iterator;
}
