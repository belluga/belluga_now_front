import 'package:belluga_now/domain/map/city_poi_model.dart';
import 'package:belluga_now/domain/map/filters/main_filter_option.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/domain/map/queries/poi_query.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:belluga_now/presentation/tenant_public/map/screens/map_screen/controllers/fab_menu_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  test('disposed controller ignores delayed state mutations', () {
    final controller = FabMenuController(
      poiRepository: _FakePoiRepository(),
    );

    controller.dispose();

    expect(
      () {
        controller.setExpanded(true);
        controller.setCondensed(true);
        controller.setRevertedOnClose(true);
        controller.setIgnoreNextFilterChange(true);
        controller.toggleExpanded();
      },
      returnsNormally,
    );
  });
}

class _FakePoiRepository implements PoiRepositoryContract {
  @override
  final StreamValue<List<CityPoiModel>?> filteredPoisStreamValue =
      StreamValue<List<CityPoiModel>?>(defaultValue: null);

  @override
  final StreamValue<CityPoiModel?> selectedPoiStreamValue =
      StreamValue<CityPoiModel?>();
  @override
  final StreamValue<List<CityPoiModel>?> stackItemsStreamValue =
      StreamValue<List<CityPoiModel>?>(defaultValue: null);

  @override
  final StreamValue<PoiFilterMode> filterModeStreamValue =
      StreamValue<PoiFilterMode>(defaultValue: PoiFilterMode.none);

  @override
  final StreamValue<PoiFilterOptions?> filterOptionsStreamValue =
      StreamValue<PoiFilterOptions?>();

  @override
  final StreamValue<List<MainFilterOption>> mainFilterOptionsStreamValue =
      StreamValue<List<MainFilterOption>>(
        defaultValue: const <MainFilterOption>[],
      );

  @override
  CityCoordinate get defaultCenter => _buildCoordinate(-20.611121, -40.498617);

  @override
  void applyFilterMode(PoiFilterMode mode) {
    filterModeStreamValue.addValue(mode);
  }

  @override
  void clearFilters() {
    filterModeStreamValue.addValue(PoiFilterMode.none);
  }

  @override
  void clearLoadedPois() {
    filteredPoisStreamValue.addValue(const <CityPoiModel>[]);
  }

  @override
  void clearSelection() {
    selectedPoiStreamValue.addValue(null);
  }

  @override
  Future<List<MainFilterOption>> fetchMainFilters() async =>
      const <MainFilterOption>[];

  @override
  Future<PoiFilterOptions> fetchFilters() async => PoiFilterOptions(
        categories: const <PoiFilterCategory>[],
      );

  @override
  Future<List<CityPoiModel>> fetchPoints(PoiQuery query) async =>
      const <CityPoiModel>[];

  @override
  Future<void> refreshPoints(PoiQuery query) async {
    final points = await fetchPoints(query);
    filteredPoisStreamValue.addValue(points);
  }

  @override
  Future<List<CityPoiModel>> fetchStackItems({
    required String stackKey,
    required PoiQuery query,
  }) async =>
      const <CityPoiModel>[];

  @override
  Future<CityPoiModel?> fetchPoiByReference({
    required String refType,
    required String refId,
  }) async =>
      null;

  @override
  Future<void> loadStackItems({
    required String stackKey,
    required PoiQuery query,
  }) async {
    final stackItems = await fetchStackItems(
      stackKey: stackKey,
      query: query,
    );
    stackItemsStreamValue.addValue(stackItems);
  }

  @override
  void selectPoi(CityPoiModel? poi) {
    selectedPoiStreamValue.addValue(poi);
  }
}

CityCoordinate _buildCoordinate(double latitude, double longitude) {
  final latitudeValue = LatitudeValue()..parse(latitude.toStringAsFixed(6));
  final longitudeValue = LongitudeValue()..parse(longitude.toStringAsFixed(6));
  return CityCoordinate(
    latitudeValue: latitudeValue,
    longitudeValue: longitudeValue,
  );
}
