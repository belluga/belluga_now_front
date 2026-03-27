import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_query_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_marker_override_dto.dart';

class MapFilterCategoryDTO {
  const MapFilterCategoryDTO({
    required this.key,
    required this.label,
    required this.count,
    required this.imageUri,
    required this.overrideMarker,
    this.markerOverride,
    required this.query,
  });

  final String key;
  final String label;
  final int count;
  final String? imageUri;
  final bool overrideMarker;
  final MapFilterMarkerOverrideDTO? markerOverride;
  final MapFilterCategoryQueryDTO query;

  factory MapFilterCategoryDTO.fromJson(Map<String, dynamic> json) {
    final rawImageUri = (json['image_uri'] ?? '').toString().trim();
    final rawQuery = json['query'];
    final queryMap = rawQuery is Map
        ? rawQuery.map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};
    return MapFilterCategoryDTO(
      key: (json['key'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      imageUri: rawImageUri.isEmpty ? null : rawImageUri,
      overrideMarker: json['override_marker'] as bool? ?? false,
      markerOverride: MapFilterMarkerOverrideDTO.tryFromJson(
        json['marker_override'],
      ),
      query: MapFilterCategoryQueryDTO.fromJson(queryMap),
    );
  }
}
