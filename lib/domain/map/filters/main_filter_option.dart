export 'main_filter_behavior.dart';
export 'main_filter_type.dart';

import 'package:belluga_now/domain/map/city_poi_category.dart';
import 'package:belluga_now/domain/map/filters/main_filter_behavior.dart';
import 'package:belluga_now/domain/map/filters/main_filter_type.dart';

typedef MainFilterOptionId = String;
typedef MainFilterOptionLabel = String;
typedef MainFilterOptionIconName = String;
typedef MainFilterOptionTag = String;
typedef MainFilterOptionTagSet = Set<MainFilterOptionTag>;
typedef MainFilterOptionMetadata = Map<String, dynamic>;

class MainFilterOption {
  const MainFilterOption({
    required this.id,
    required this.label,
    required this.iconName,
    required this.type,
    required this.behavior,
    this.categories,
    this.tags,
    this.metadata = const <MainFilterOptionTag, dynamic>{},
  });

  /// Unique identifier for analytics/toggling.
  final MainFilterOptionId id;

  /// Display label shown alongside the FAB.
  final MainFilterOptionLabel label;

  /// Material icon name that represents this filter.
  final MainFilterOptionIconName iconName;

  final MainFilterType type;

  final MainFilterBehavior behavior;

  /// Categories that should be applied when the filter is executed.
  final Set<CityPoiCategory>? categories;

  /// Tags that should be enforced when the filter is executed.
  final MainFilterOptionTagSet? tags;

  /// Additional metadata to support specialised panels (e.g., slug, region list key).
  final MainFilterOptionMetadata metadata;

  bool get opensPanel => behavior == MainFilterBehavior.opensPanel;

  bool get isQuickApply => behavior == MainFilterBehavior.quickApply;
}
