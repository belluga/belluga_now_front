class MapFilterTaxonomyTermDTO {
  const MapFilterTaxonomyTermDTO({
    required this.type,
    required this.value,
    required this.label,
    required this.count,
    this.name,
    this.taxonomyName,
  });

  final String type;
  final String value;
  final String label;
  final int count;
  final String? name;
  final String? taxonomyName;

  String get displayLabel {
    final displayName = name?.trim() ?? '';
    if (displayName.isNotEmpty) {
      return displayName;
    }
    final compatibilityLabel = label.trim();
    if (compatibilityLabel.isNotEmpty) {
      return compatibilityLabel;
    }
    return value;
  }

  factory MapFilterTaxonomyTermDTO.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString();
    final label = json['label']?.toString();
    final value = (json['value'] ?? '').toString();
    return MapFilterTaxonomyTermDTO(
      type: (json['type'] ?? '').toString(),
      value: value,
      name: name,
      taxonomyName: json['taxonomy_name']?.toString(),
      label: (name != null && name.trim().isNotEmpty)
          ? name
          : ((label != null && label.trim().isNotEmpty) ? label : value),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
