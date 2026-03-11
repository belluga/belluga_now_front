import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/mappers/map_dto_mapper.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/map/laravel_map_poi_http_service.dart';

class CityMapRepository extends CityMapRepositoryContract with MapDtoMapper {
  CityMapRepository({
    LaravelMapPoiHttpService? laravelHttpService,
  }) : _laravelHttpService = laravelHttpService ?? LaravelMapPoiHttpService();

  final LaravelMapPoiHttpService _laravelHttpService;
  static const Stream<PoiUpdateEvent?> _emptyPoiEvents = Stream.empty();

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    final dtos = await _laravelHttpService.getPois(query);
    return dtos.map(mapCityPoi).toList(growable: false);
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required PoiQuery query,
    required String stackKey,
  }) async {
    final dtos = await _laravelHttpService.getPois(
      query,
      stackKey: stackKey,
    );
    if (dtos.isEmpty) {
      return const <CityPoiModel>[];
    }
    final stackItems = dtos.first.items.map(mapCityPoi).toList(growable: false);
    if (stackItems.isEmpty) {
      return dtos.map(mapCityPoi).toList(growable: false);
    }
    return _attachStackContext(
      stackItems,
      stackKey: stackKey,
      stackCount:
          dtos.first.stackCount > 0 ? dtos.first.stackCount : stackItems.length,
    );
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
            stackKey: normalizedStackKey,
            stackCount: normalizedCount,
          ),
        )
        .toList(growable: false);
    return seeded
        .map(
          (item) => item.copyWith(
            stackItems: seeded,
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
      categoryKeys.add(key);
      categories.add(
        PoiFilterCategory(
          key: key,
          label: category.label.trim().isEmpty ? key : category.label.trim(),
          imageUri: category.imageUri,
          count: category.count,
          tags: tags,
          serverQuery: PoiFilterServerQuery(
            source:
                querySource == null || querySource.isEmpty ? null : querySource,
            types: queryTypes,
            categoryKeys: queryCategoryKeys,
            taxonomy: queryTaxonomy,
            tags: queryTags,
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
              type: type,
              value: value,
              label: term.label.trim().isEmpty ? value : term.label.trim(),
              count: term.count,
            ),
          );
    }

    final taxonomyGroups = groupedTaxonomy.entries.map((entry) {
      final terms = List<PoiFilterTaxonomyTerm>.from(entry.value)
        ..sort((left, right) => left.label.compareTo(right.label));
      return PoiFilterTaxonomyGroup(
        type: entry.key,
        label: _humanizeTaxonomyType(entry.key),
        terms: terms,
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
  Future<String> fetchFallbackEventImage() async {
    return '';
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
}
