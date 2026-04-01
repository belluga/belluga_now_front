import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_image_uri_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_source_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_term_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_token_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_tag_value.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/map/laravel_map_poi_http_service.dart';

class CityMapRepository extends CityMapRepositoryContract {
  CityMapRepository({
    LaravelMapPoiHttpService? laravelHttpService,
  }) : _laravelHttpService = laravelHttpService ?? LaravelMapPoiHttpService();

  final LaravelMapPoiHttpService _laravelHttpService;
  static const Stream<PoiUpdateEvent?> _emptyPoiEvents = Stream.empty();

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    final dtos = await _laravelHttpService.getPois(query);
    return dtos.map((dto) => dto.toDomain()).toList(growable: false);
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required PoiQuery query,
    required PoiStackKeyValue stackKey,
  }) async {
    final dtos = await _laravelHttpService.getPois(
      query,
      stackKey: stackKey.value,
    );
    if (dtos.isEmpty) {
      return const <CityPoiModel>[];
    }
    final stackItems =
        dtos.first.items.map((item) => item.toDomain()).toList(growable: false);
    if (stackItems.isEmpty) {
      return dtos.map((dto) => dto.toDomain()).toList(growable: false);
    }
    return _attachStackContext(
      stackItems,
      stackKey: stackKey.value,
      stackCount:
          dtos.first.stackCount > 0 ? dtos.first.stackCount : stackItems.length,
    );
  }

  @override
  Future<CityPoiModel?> fetchPoiByReference({
    required PoiReferenceTypeValue refType,
    required PoiReferenceIdValue refId,
  }) async {
    final dto = await _laravelHttpService.lookupPoiByReference(
      refType: refType.value,
      refId: refId.value,
    );
    return dto?.toDomain();
  }

  List<CityPoiModel> _attachStackContext(
    List<CityPoiModel> items, {
    required String stackKey,
    required int stackCount,
  }) {
    if (items.isEmpty) {
      return const <CityPoiModel>[];
    }
    final normalizedStackKey =
        stackKey.trim().isNotEmpty ? stackKey.trim() : items.first.stackKey;
    final normalizedCount = stackCount > 0 ? stackCount : items.length;
    final seeded = items
        .map(
          (item) => item.copyWith(
            stackKeyValue: _parseStackKeyValue(normalizedStackKey),
            stackCountValue: _parseStackCountValue(normalizedCount),
          ),
        )
        .toList(growable: false);
    final stackItems = CityPoiStackItems();
    for (final item in seeded) {
      stackItems.add(item);
    }
    return seeded
        .map(
          (item) => item.copyWith(
            stackItems: stackItems,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<PoiFilterOptions> fetchFilters() async {
    final filters = await _laravelHttpService.getFilters(PoiQuery());
    final tags = filters.tags
        .map((tag) => tag.key.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet();

    final categories = <PoiFilterCategory>[];
    final categoryKeys = <String>{};
    for (final category in filters.categories) {
      final key = category.key.trim().toLowerCase();
      if (key.isEmpty || categoryKeys.contains(key)) {
        continue;
      }
      final resolvedQuery = category.query;
      final queryCategoryKeys = resolvedQuery.categoryKeys
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet();
      final queryTaxonomy = resolvedQuery.taxonomy
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet();
      final queryTags = resolvedQuery.tags
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet();
      final querySource = resolvedQuery.source?.trim().toLowerCase();
      final queryTypes = resolvedQuery.types
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet();
      final keyValue = _parseKeyValue(key);
      final labelValue = _parseLabelValue(
        category.label.trim().isEmpty ? key : category.label.trim(),
      );
      categoryKeys.add(key);
      categories.add(
        PoiFilterCategory(
          keyValue: keyValue,
          labelValue: labelValue,
          imageUriValue: _parseImageUriValue(category.imageUri),
          countValue: _parseCountValue(category.count),
          overrideMarkerValue: _parseBooleanValue(category.overrideMarker),
          markerOverride: category.markerOverride?.toDomain(),
          tagValues: _parseTagValues(tags),
          serverQuery: PoiFilterServerQuery(
            sourceValue: _parseSourceValue(querySource),
            typeValues: _parseTypeValues(queryTypes),
            categoryKeyValues: _parseCategoryKeyValues(queryCategoryKeys),
            taxonomyTokenValues: _parseTaxonomyValues(queryTaxonomy),
            tagValues: _parseTagValues(queryTags),
          ),
        ),
      );
    }

    final groupedTaxonomy = <String, List<PoiFilterTaxonomyTerm>>{};
    for (final term in filters.taxonomyTerms) {
      final type = term.type.trim().toLowerCase();
      final value = term.value.trim().toLowerCase();
      if (type.isEmpty || value.isEmpty) {
        continue;
      }
      groupedTaxonomy.putIfAbsent(type, () => <PoiFilterTaxonomyTerm>[]).add(
            PoiFilterTaxonomyTerm(
              typeValue: _parseTaxonomyTypeValue(type),
              valueValue: _parseTaxonomyTermValue(value),
              labelValue: _parseLabelValue(
                term.label.trim().isEmpty ? value : term.label.trim(),
              ),
              countValue: _parseCountValue(term.count),
            ),
          );
    }

    final taxonomyGroups = groupedTaxonomy.entries.map((entry) {
      final terms = List<PoiFilterTaxonomyTerm>.from(entry.value)
        ..sort((left, right) => left.label.compareTo(right.label));
      final taxonomyTerms = PoiFilterTaxonomyTerms();
      for (final term in terms) {
        taxonomyTerms.add(term);
      }
      return PoiFilterTaxonomyGroup(
        typeValue: _parseTaxonomyTypeValue(entry.key),
        labelValue: _parseLabelValue(_humanizeTaxonomyType(entry.key)),
        terms: taxonomyTerms,
      );
    }).toList(growable: false)
      ..sort((left, right) => left.label.compareTo(right.label));

    return PoiFilterOptions(
      categories: List<PoiFilterCategory>.unmodifiable(categories),
      taxonomyGroups: taxonomyGroups,
    );
  }

  String _humanizeTaxonomyType(String type) {
    final normalized = type.trim();
    if (normalized.isEmpty) {
      return 'Taxonomia';
    }
    return normalized
        .split(RegExp(r'[_\s-]+'))
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) =>
              segment[0].toUpperCase() + segment.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  @override
  Future<List<MainFilterOption>> fetchMainFilters() async {
    return const <MainFilterOption>[];
  }

  @override
  Future<List<MapRegionDefinition>> fetchRegions() async {
    return const <MapRegionDefinition>[];
  }

  @override
  Future<ThumbUriValue> fetchFallbackEventImage() async {
    final value = ThumbUriValue(
      defaultValue: Uri.parse('asset://event-placeholder'),
    );
    value.parse(value.defaultValue.toString());
    return value;
  }

  @override
  Stream<PoiUpdateEvent?> get poiEvents => _emptyPoiEvents;

  @override
  CityCoordinate defaultCenter() => CityCoordinate(
        latitudeValue: LatitudeValue()..parse('-20.673067'),
        longitudeValue: LongitudeValue()..parse('-40.498383'),
      );

  @override
  void dispose() {}

  PoiFilterKeyValue _parseKeyValue(String raw) {
    final value = PoiFilterKeyValue();
    value.parse(raw.trim().toLowerCase());
    return value;
  }

  PoiFilterLabelValue _parseLabelValue(String raw) {
    final value = PoiFilterLabelValue();
    value.parse(raw.trim());
    return value;
  }

  PoiFilterImageUriValue? _parseImageUriValue(String? raw) {
    final normalized = raw?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    final value = PoiFilterImageUriValue();
    value.parse(normalized);
    return value;
  }

  PoiFilterCountValue _parseCountValue(int raw) {
    final value = PoiFilterCountValue();
    value.parse(raw.toString());
    return value;
  }

  PoiBooleanValue _parseBooleanValue(bool raw) {
    final value = PoiBooleanValue();
    value.parse(raw.toString());
    return value;
  }

  PoiFilterSourceValue? _parseSourceValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final value = PoiFilterSourceValue();
    value.parse(raw.trim().toLowerCase());
    return value;
  }

  List<PoiTagValue> _parseTagValues(Iterable<String> rawValues) {
    final values = <PoiTagValue>[];
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiTagValue();
      value.parse(normalized);
      values.add(value);
    }
    return List<PoiTagValue>.unmodifiable(values.toSet().toList());
  }

  List<PoiFilterTypeValue> _parseTypeValues(Iterable<String> rawValues) {
    final values = <PoiFilterTypeValue>[];
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiFilterTypeValue();
      value.parse(normalized);
      values.add(value);
    }
    return List<PoiFilterTypeValue>.unmodifiable(values.toSet().toList());
  }

  List<PoiFilterKeyValue> _parseCategoryKeyValues(Iterable<String> rawValues) {
    final values = <PoiFilterKeyValue>[];
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiFilterKeyValue();
      value.parse(normalized);
      values.add(value);
    }
    return List<PoiFilterKeyValue>.unmodifiable(values.toSet().toList());
  }

  List<PoiFilterTaxonomyTokenValue> _parseTaxonomyValues(
    Iterable<String> rawValues,
  ) {
    final values = <PoiFilterTaxonomyTokenValue>[];
    for (final entry in rawValues) {
      final normalized = entry.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      final value = PoiFilterTaxonomyTokenValue();
      value.parse(normalized);
      values.add(value);
    }
    return List<PoiFilterTaxonomyTokenValue>.unmodifiable(
      values.toSet().toList(),
    );
  }

  PoiFilterTaxonomyTypeValue _parseTaxonomyTypeValue(String raw) {
    final value = PoiFilterTaxonomyTypeValue();
    value.parse(raw.trim().toLowerCase());
    return value;
  }

  PoiFilterTaxonomyTermValue _parseTaxonomyTermValue(String raw) {
    final value = PoiFilterTaxonomyTermValue();
    value.parse(raw.trim().toLowerCase());
    return value;
  }

  PoiStackKeyValue _parseStackKeyValue(String raw) {
    final value = PoiStackKeyValue();
    value.parse(raw.trim());
    return value;
  }

  PoiStackCountValue _parseStackCountValue(int raw) {
    final value = PoiStackCountValue();
    value.parse(raw.toString());
    return value;
  }
}
