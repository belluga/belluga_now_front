part of 'discovery_filter_entity_registry.dart';

class DiscoveryFilterTaxonomyOption {
  const DiscoveryFilterTaxonomyOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;

  bool get isValid => key.trim().isNotEmpty && label.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'key': key,
        'label': label,
      };
}
