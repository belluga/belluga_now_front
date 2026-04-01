import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_tag_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_taxonomy_term_dto.dart';

export 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_dto.dart';
export 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_query_dto.dart';
export 'package:belluga_now/infrastructure/dal/dto/map/map_filter_marker_override_dto.dart';
export 'package:belluga_now/infrastructure/dal/dto/map/map_filter_tag_dto.dart';
export 'package:belluga_now/infrastructure/dal/dto/map/map_filter_taxonomy_term_dto.dart';

class MapFiltersDTO {
  const MapFiltersDTO({
    required this.categories,
    required this.tags,
    required this.taxonomyTerms,
  });

  final List<MapFilterCategoryDTO> categories;
  final List<MapFilterTagDTO> tags;
  final List<MapFilterTaxonomyTermDTO> taxonomyTerms;

  factory MapFiltersDTO.fromJson(Map<String, dynamic> json) {
    return MapFiltersDTO(
      categories: _normalizeMapList(json['categories'])
          .map(MapFilterCategoryDTO.fromJson)
          .toList(growable: false),
      tags: _normalizeMapList(json['tags'])
          .map(MapFilterTagDTO.fromJson)
          .toList(growable: false),
      taxonomyTerms: _normalizeMapList(json['taxonomy_terms'])
          .map(MapFilterTaxonomyTermDTO.fromJson)
          .toList(growable: false),
    );
  }

  static List<Map<String, dynamic>> _normalizeMapList(Object? raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }

    return raw
        .map(_normalizeMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Map<String, dynamic>? _normalizeMap(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    return raw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
}
