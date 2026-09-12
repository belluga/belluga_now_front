import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
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
        ? rawQuery.map((key, value) => MapEntry(key.toString(), value))
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

  PoiFilterCategory? toDomain() {
    final normalizedKey = key.trim().toLowerCase();
    if (normalizedKey.isEmpty) {
      return null;
    }
    final normalizedSource = query.source?.trim().toLowerCase();
    if (normalizedSource == null || normalizedSource.isEmpty) {
      return null;
    }
    final keyValue = PoiFilterKeyValue()..parse(normalizedKey);
    final labelValue = PoiFilterLabelValue()
      ..parse(label.trim().isEmpty ? normalizedKey : label.trim());
    final countValue = PoiFilterCountValue()..parse('0');
    final overrideMarkerValue = PoiBooleanValue()
      ..parse(overrideMarker.toString());
    final sourceValue = PoiFilterSourceValue()..parse(normalizedSource);

    T parseValue<T>(String raw, T Function() factory) {
      final value = factory();
      (value as dynamic).parse(raw.trim().toLowerCase());
      return value;
    }

    final imageValue = imageUri == null
        ? null
        : (PoiFilterImageUriValue()..parse(imageUri));
    return PoiFilterCategory(
      keyValue: keyValue,
      labelValue: labelValue,
      imageUriValue: imageValue,
      countValue: countValue,
      overrideMarkerValue: overrideMarkerValue,
      markerOverride: markerOverride?.toDomain(),
      tagValues: const <PoiTagValue>[],
      serverQuery: PoiFilterServerQuery(
        sourceValue: sourceValue,
        typeValues: query.types
            .map((value) => parseValue(value, PoiFilterTypeValue.new))
            .toSet()
            .toList(growable: false),
        categoryKeyValues: query.categoryKeys
            .map((value) => parseValue(value, PoiFilterKeyValue.new))
            .toSet()
            .toList(growable: false),
        taxonomyTokenValues: query.taxonomy
            .map((value) => parseValue(value, PoiFilterTaxonomyTokenValue.new))
            .toSet()
            .toList(growable: false),
        tagValues: query.tags
            .map((value) => parseValue(value, PoiTagValue.new))
            .toSet()
            .toList(growable: false),
      ),
    );
  }
}
