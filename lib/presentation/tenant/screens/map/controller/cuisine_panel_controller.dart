import 'dart:async';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_options.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/city_map_controller.dart';
import 'package:belluga_now/presentation/tenant/screens/map/controller/fab_menu_controller.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class CuisinePanelController implements Disposable {
  CuisinePanelController({
    CityMapController? mapController,
    FabMenuController? fabMenuController,
  })  : _mapController = mapController ?? GetIt.I.get<CityMapController>(),
        _fabMenuController =
            fabMenuController ?? GetIt.I.get<FabMenuController>(),
        availableTags = StreamValue<List<String>>(defaultValue: const []) {
    _filterOptionsSubscription =
        _mapController.filterOptionsStreamValue.stream.listen(_handleOptions);
    _selectedCategoriesSubscription = _mapController.selectedCategories.stream
        .listen(_handleSelectedCategories);
  }

  final CityMapController _mapController;
  final FabMenuController _fabMenuController;

  final StreamValue<List<String>> availableTags;

  StreamValue<Set<String>> get selectedTags => _mapController.selectedTags;

  bool isTagSelected(String tag) =>
      _mapController.selectedTags.value.contains(tag);

  StreamSubscription<PoiFilterOptions?>? _filterOptionsSubscription;
  StreamSubscription<Set<CityPoiCategory>>? _selectedCategoriesSubscription;

  Future<void> activate() async {
    await _mapController.loadFilters();
    final categories = _mapController.selectedCategories.value;
    if (!categories.contains(CityPoiCategory.restaurant)) {
      _mapController.toggleCategory(CityPoiCategory.restaurant);
    } else {
      _refreshTags();
    }
  }

  void toggleTag(String tag) {
    _mapController.toggleTag(tag);
  }

  void closePanel() {
    _fabMenuController.closePanel();
  }

  @override
  void onDispose() {
    availableTags.dispose();
    _filterOptionsSubscription?.cancel();
    _selectedCategoriesSubscription?.cancel();
  }

  void _handleOptions(PoiFilterOptions? _) {
    _refreshTags();
  }

  void _handleSelectedCategories(Set<CityPoiCategory> _) {
    _refreshTags();
  }

  void _refreshTags() {
    final options = _mapController.filterOptionsStreamValue.value;
    final selected = _mapController.selectedCategories.value;
    if (options == null || selected.isEmpty) {
      availableTags.addValue(const <String>[]);
      return;
    }
    final tags = options.tagsForCategories(selected).toList()..sort();
    availableTags.addValue(tags);
  }
}
