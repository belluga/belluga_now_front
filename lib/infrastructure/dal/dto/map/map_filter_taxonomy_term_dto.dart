class MapFilterTaxonomyTermDTO {
  const MapFilterTaxonomyTermDTO({
    required this.type,
    required this.value,
    required this.label,
    required this.count,
  });

  final String type;
  final String value;
  final String label;
  final int count;

  factory MapFilterTaxonomyTermDTO.fromJson(Map<String, dynamic> json) {
    return MapFilterTaxonomyTermDTO(
      type: (json['type'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
