part of 'discovery_filter_entity_registry.dart';

abstract class DiscoveryFilterEntityProvider {
  String get entity;

  List<DiscoveryFilterTypeOption> typeOptions();

  List<DiscoveryFilterTaxonomyOption> taxonomiesForTypes(Set<String> typeKeys);
}
