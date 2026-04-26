part of 'discovery_filter_selection_repair.dart';

class DiscoveryFilterSelectionRepairResult {
  const DiscoveryFilterSelectionRepairResult({
    required this.selection,
    required this.changed,
    this.droppedPrimaryKeys = const <String>{},
    this.droppedTaxonomyTerms = const <String, Set<String>>{},
  });

  final DiscoveryFilterSelection selection;
  final bool changed;
  final Set<String> droppedPrimaryKeys;
  final Map<String, Set<String>> droppedTaxonomyTerms;
}
