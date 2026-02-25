import 'package:belluga_now/domain/map/filters/poi_filter_mode.dart';
import 'package:belluga_now/domain/repositories/poi_repository_contract.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class FabMenuController {
  FabMenuController({
    PoiRepositoryContract? poiRepository,
  }) : _poiRepository = poiRepository ?? GetIt.I.get<PoiRepositoryContract>();

  final PoiRepositoryContract _poiRepository;

  final expandedStreamValue = StreamValue<bool>(defaultValue: true);
  final condensedStreamValue = StreamValue<bool>(defaultValue: false);
  final revertedOnCloseStreamValue = StreamValue<bool>(defaultValue: false);
  final ignoreNextFilterChangeStreamValue =
      StreamValue<bool>(defaultValue: false);
  PoiFilterMode previousFilterMode = PoiFilterMode.none;
  PoiFilterMode? lastFilterMode;
  bool? lastExpanded;

  StreamValue<PoiFilterMode> get filterModeStreamValue =>
      _poiRepository.filterModeStreamValue;

  void toggleFilterMode(PoiFilterMode mode) {
    final current = filterModeStreamValue.value;
    if (current == mode) {
      _poiRepository.clearFilters();
    } else {
      _poiRepository.applyFilterMode(mode);
    }
  }

  void toggleExpanded() {
    final current = expandedStreamValue.value;
    expandedStreamValue.addValue(!current);
  }

  void setExpanded(bool expanded) {
    expandedStreamValue.addValue(expanded);
  }

  void setCondensed(bool condensed) {
    condensedStreamValue.addValue(condensed);
  }

  void setRevertedOnClose(bool reverted) {
    revertedOnCloseStreamValue.addValue(reverted);
  }

  void setIgnoreNextFilterChange(bool value) {
    ignoreNextFilterChangeStreamValue.addValue(value);
  }

  void dispose() {
    expandedStreamValue.dispose();
    condensedStreamValue.dispose();
    revertedOnCloseStreamValue.dispose();
    ignoreNextFilterChangeStreamValue.dispose();
  }
}
