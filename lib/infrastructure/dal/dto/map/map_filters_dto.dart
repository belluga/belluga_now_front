import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_tag_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_taxonomy_term_dto.dart';

export 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_dto.dart';
export 'package:belluga_now/infrastructure/dal/dto/map/map_filter_category_query_dto.dart';
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
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MapFilterCategoryDTO.fromJson)
          .toList(growable: false),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MapFilterTagDTO.fromJson)
          .toList(growable: false),
      taxonomyTerms: (json['taxonomy_terms'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MapFilterTaxonomyTermDTO.fromJson)
          .toList(growable: false),
    );
  }
}
