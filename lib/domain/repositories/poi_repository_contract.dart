import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:stream_value/core/stream_value.dart';

typedef PoiRepositoryContractPrimString = String;
typedef PoiRepositoryContractPrimInt = int;
typedef PoiRepositoryContractPrimBool = bool;
typedef PoiRepositoryContractPrimDouble = double;
typedef PoiRepositoryContractPrimDateTime = DateTime;
typedef PoiRepositoryContractPrimDynamic = dynamic;

abstract class PoiRepositoryContract {
  StreamValue<List<CityPoiModel>?> get filteredPoisStreamValue;
  StreamValue<CityPoiModel?> get selectedPoiStreamValue;
  StreamValue<List<CityPoiModel>?> get stackItemsStreamValue;
  StreamValue<PoiFilterMode> get filterModeStreamValue;
  StreamValue<PoiFilterOptions?> get filterOptionsStreamValue;
  StreamValue<List<MainFilterOption>> get mainFilterOptionsStreamValue;

  CityCoordinate get defaultCenter;

  Future<List<CityPoiModel>> fetchPoints(PoiQuery query);
  Future<void> refreshPoints(PoiQuery query);
  Future<List<CityPoiModel>> fetchStackItems({
    required PoiRepositoryContractPrimString stackKey,
    required PoiQuery query,
  });
  Future<CityPoiModel?> fetchPoiByReference({
    required PoiRepositoryContractPrimString refType,
    required PoiRepositoryContractPrimString refId,
  });
  Future<void> loadStackItems({
    required PoiRepositoryContractPrimString stackKey,
    required PoiQuery query,
  }) async {
    final items = await fetchStackItems(
      stackKey: stackKey,
      query: query,
    );
    stackItemsStreamValue.addValue(items);
  }

  Future<PoiFilterOptions> fetchFilters();
  Future<List<MainFilterOption>> fetchMainFilters();

  void selectPoi(CityPoiModel? poi);
  void clearSelection();
  void clearLoadedPois();
  void applyFilterMode(PoiFilterMode mode);
  void clearFilters();
}
