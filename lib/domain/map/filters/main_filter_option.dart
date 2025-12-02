import 'package:belluga_now/domain/map/city_poi_category.dart';

/// Identifies a high-level, discoverable filter that can be surfaced as a FAB.
enum MainFilterType {
  promotions,
  events,
  music,
  regions,
  cuisines,
}

/// Describes how a main filter should behave when activated.
enum MainFilterBehavior {
  quickApply,
  opensPanel,
}

class MainFilterOption {
  const MainFilterOption({
    required this.id,
    required this.label,
    required this.iconName,
    required this.type,
    required this.behavior,
    this.categories,
    this.tags,
    this.metadata = const <String, dynamic>{},
  });

  /// Unique identifier for analytics/toggling.
  final String id;

  /// Display label shown alongside the FAB.
  final String label;

  /// Material icon name that represents this filter.
  final String iconName;

  final MainFilterType type;

  final MainFilterBehavior behavior;

  /// Categories that should be applied when the filter is executed.
  final Set<CityPoiCategory>? categories;

  /// Tags that should be enforced when the filter is executed.
  final Set<String>? tags;

  /// Additional metadata to support specialised panels (e.g., slug, region list key).
  final Map<String, dynamic> metadata;

  bool get opensPanel => behavior == MainFilterBehavior.opensPanel;

  bool get isQuickApply => behavior == MainFilterBehavior.quickApply;
}
