import 'package:belluga_now/infrastructure/repositories/poi_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

class FabMenuController {
  FabMenuController({
    PoiRepository? poiRepository,
  }) : _poiRepository = poiRepository ?? GetIt.I.get<PoiRepository>();

  final PoiRepository _poiRepository;

  final expandedStreamValue = StreamValue<bool>(defaultValue: true);

  StreamValue<PoiFilterMode> get filterModeStreamValue =>
      _poiRepository.filterModeStreamValue;

  void toggleEventFilter() {
    final current = filterModeStreamValue.value;
    final next = current == PoiFilterMode.events
        ? PoiFilterMode.none
        : PoiFilterMode.events;
    _poiRepository.applyFilterMode(next);
  }

  void toggleExpanded() {
    final current = expandedStreamValue.value;
    expandedStreamValue.addValue(!current);
  }

  void setExpanded(bool expanded) {
    expandedStreamValue.addValue(expanded);
  }
}
