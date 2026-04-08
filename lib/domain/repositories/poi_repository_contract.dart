import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_id_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_reference_type_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_stack_key_value.dart';
import 'package:belluga_now/domain/schedule/event_model.dart';
import 'package:belluga_now/domain/static_assets/public_static_asset_model.dart';
import 'package:stream_value/core/stream_value.dart';

abstract class PoiRepositoryContract {
  StreamValue<List<CityPoiModel>?> get filteredPoisStreamValue;
  StreamValue<CityPoiModel?> get selectedPoiStreamValue;
  StreamValue<List<CityPoiModel>?> get stackItemsStreamValue;
  StreamValue<PoiFilterMode> get filterModeStreamValue;
  StreamValue<PoiFilterOptions?> get filterOptionsStreamValue;
  StreamValue<int> get poiHydrationRevisionStreamValue;

  CityCoordinate get defaultCenter;

  Future<List<CityPoiModel>> fetchPoints(PoiQuery query);
  Future<void> refreshPoints(PoiQuery query);
  Future<List<CityPoiModel>> fetchStackItems({
    required PoiStackKeyValue stackKey,
    required PoiQuery query,
  });
  Future<CityPoiModel?> fetchPoiByReference({
    required PoiReferenceTypeValue refType,
    required PoiReferenceIdValue refId,
  });
  Future<void> loadStackItems({
    required PoiStackKeyValue stackKey,
    required PoiQuery query,
  }) async {
    final items = await fetchStackItems(
      stackKey: stackKey,
      query: query,
    );
    stackItemsStreamValue.addValue(items);
  }

  Future<PoiFilterOptions> fetchFilters();
  Future<void> ensurePoiHydrated(CityPoiModel poi);

  void selectPoi(CityPoiModel? poi);
  void clearSelection();
  void setStackItems(List<CityPoiModel>? items);
  void clearStackItems();
  void clearLoadedPois();
  void applyFilterMode(PoiFilterMode mode);
  void clearFilters();

  AccountProfileModel? hydratedAccountProfileForPoi(CityPoiModel poi);
  EventModel? hydratedEventForPoi(CityPoiModel poi);
  PublicStaticAssetModel? hydratedStaticAssetForPoi(CityPoiModel poi);
}
