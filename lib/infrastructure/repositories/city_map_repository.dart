import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/projections/city_poi_stack_items.dart';
import 'package:belluga_now/domain/map/projections/poi_filter_page.dart';
import 'package:belluga_now/domain/map/projections/poi_scene_result.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/poi_boolean_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_positive_int_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/repositories/city_map_repository_contract.dart';
import 'package:belluga_now/domain/value_objects/thumb_uri_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/map/laravel_map_poi_http_service.dart';

class CityMapRepository extends CityMapRepositoryContract {
  CityMapRepository({LaravelMapPoiHttpService? laravelHttpService})
    : _laravelHttpService = laravelHttpService ?? LaravelMapPoiHttpService();

  final LaravelMapPoiHttpService _laravelHttpService;
  static const Stream<PoiUpdateEvent?> _emptyPoiEvents = Stream.empty();

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async {
    return (await fetchScene(query)).points;
  }

  @override
  Future<PoiSceneResult> fetchScene(PoiQuery query) async {
    final dto = await _laravelHttpService.getPois(query);
    return PoiSceneResult(
      points: dto.points
          .map((point) => point.toDomain())
          .toList(growable: false),
      isPartialValue: PoiBooleanValue()..parse(dto.isPartial.toString()),
    );
  }

  @override
  Future<PoiFilterPage> fetchFilterPage(
    PoiQuery query, {
    required PoiPositiveIntValue page,
    required PoiPositiveIntValue pageSize,
  }) async {
    final dto = await _laravelHttpService.getNearPage(
      query,
      page: page.value,
      pageSize: pageSize.value,
    );
    return PoiFilterPage(
      pageValue: PoiPositiveIntValue()..parse(dto.page.toString()),
      pageSizeValue: PoiPositiveIntValue()..parse(dto.pageSize.toString()),
      hasMoreValue: PoiBooleanValue()..parse(dto.hasMore.toString()),
      items: dto.items.map((item) => item.toDomain()).toList(growable: false),
    );
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required PoiQuery query,
    required PoiStackKeyValue stackKey,
  }) async {
    final scene = await _laravelHttpService.getPois(
      query,
      stackKey: stackKey.value,
    );
    final dtos = scene.points;
    if (dtos.isEmpty) {
      return const <CityPoiModel>[];
    }
    final stackItems = dtos.first.items
        .map((item) => item.toDomain())
        .toList(growable: false);
    if (stackItems.isEmpty) {
      return dtos.map((dto) => dto.toDomain()).toList(growable: false);
    }
    return _attachStackContext(
      stackItems,
      stackKey: stackKey.value,
      stackCount: dtos.first.stackCount > 0
          ? dtos.first.stackCount
          : stackItems.length,
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
    final normalizedStackKey = stackKey.trim().isNotEmpty
        ? stackKey.trim()
        : items.first.stackKey;
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
        .map((item) => item.copyWith(stackItems: stackItems))
        .toList(growable: false);
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
