part of 'discovery_filter_entity_registry.dart';

class DiscoveryFilterTypeOption {
  const DiscoveryFilterTypeOption({
    required this.value,
    required this.label,
    this.visual = const <String, Object?>{},
    this.allowedTaxonomyKeys = const <String>{},
  });

  factory DiscoveryFilterTypeOption.fromJson(Map<String, Object?> json) {
    return DiscoveryFilterTypeOption(
      value: _readString(json['value']) ?? '',
      label: _readString(json['label']) ?? _readString(json['value']) ?? '',
      visual: _readMap(json['visual']),
      allowedTaxonomyKeys: _readStringSet(
        json['allowed_taxonomies'] ?? json['allowedTaxonomies'],
      ),
    );
  }

  final String value;
  final String label;
  final Map<String, Object?> visual;
  final Set<String> allowedTaxonomyKeys;

  bool get isValid => value.trim().isNotEmpty && label.trim().isNotEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'value': value,
        'label': label,
        if (visual.isNotEmpty) 'visual': visual,
        if (allowedTaxonomyKeys.isNotEmpty)
          'allowed_taxonomies': allowedTaxonomyKeys.toList(growable: false),
      };
}
