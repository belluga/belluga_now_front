import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/events/poi_update_event.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/map_region_definition.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';

typedef CityMapRepositoryContractPrimString = String;
typedef CityMapRepositoryContractPrimInt = int;
typedef CityMapRepositoryContractPrimBool = bool;
typedef CityMapRepositoryContractPrimDouble = double;
typedef CityMapRepositoryContractPrimDateTime = DateTime;
typedef CityMapRepositoryContractPrimDynamic = dynamic;

abstract class CityMapRepositoryContract {
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query);

  Future<List<CityPoiModel>> fetchStackItems({
    required PoiQuery query,
    required CityMapRepositoryContractPrimString stackKey,
  });

  Future<PoiFilterOptions> fetchFilters();

  Future<List<MainFilterOption>> fetchMainFilters();

  Future<List<MapRegionDefinition>> fetchRegions();

  Future<CityMapRepositoryContractPrimString> fetchFallbackEventImage();

  Stream<PoiUpdateEvent?> get poiEvents;

  CityCoordinate defaultCenter();

  void dispose();
}
