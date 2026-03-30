import 'package:belluga_now/domain/map/filters/poi_filter_category.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_taxonomy_group.dart';

export 'package:belluga_now/domain/map/filters/poi_filter_category.dart';
export 'package:belluga_now/domain/map/filters/poi_filter_marker_override.dart';
export 'package:belluga_now/domain/map/filters/poi_filter_server_query.dart';
export 'package:belluga_now/domain/map/filters/poi_filter_taxonomy_group.dart';
export 'package:belluga_now/domain/map/filters/poi_filter_taxonomy_term.dart';

class PoiFilterOptions {
  PoiFilterOptions({
    required this.categories,
    this.taxonomyGroups = const <PoiFilterTaxonomyGroup>[],
  });

  final List<PoiFilterCategory> categories;
  final List<PoiFilterTaxonomyGroup> taxonomyGroups;

  List<PoiFilterCategory> get sortedCategories =>
      List<PoiFilterCategory>.from(categories);
}
