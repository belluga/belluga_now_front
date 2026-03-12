class MapFilterTagDTO {
  const MapFilterTagDTO({
    required this.key,
    required this.label,
    required this.count,
  });

  final String key;
  final String label;
  final int count;

  factory MapFilterTagDTO.fromJson(Map<String, dynamic> json) {
    return MapFilterTagDTO(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
