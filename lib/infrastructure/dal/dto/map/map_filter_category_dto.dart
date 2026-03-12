import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_query_dto.dart';

class MapFilterCategoryDTO {
  const MapFilterCategoryDTO({
    required this.key,
    required this.label,
    required this.count,
    required this.imageUri,
    required this.query,
  });

  final String key;
  final String label;
  final int count;
  final String? imageUri;
  final MapFilterCategoryQueryDTO query;

  factory MapFilterCategoryDTO.fromJson(Map<String, dynamic> json) {
    final rawImageUri = (json['image_uri'] ?? '').toString().trim();
    final rawQuery = json['query'];
    final queryMap = rawQuery is Map
        ? Map<String, dynamic>.from(rawQuery)
        : const <String, dynamic>{};
    return MapFilterCategoryDTO(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      imageUri: rawImageUri.isEmpty ? null : rawImageUri,
      query: MapFilterCategoryQueryDTO.fromJson(queryMap),
    );
  }
}
