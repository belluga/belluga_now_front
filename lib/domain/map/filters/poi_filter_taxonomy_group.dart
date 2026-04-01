export 'package:belluga_now/domain/map/filters/poi_filter_taxonomy_terms.dart';

import 'package:belluga_now/domain/map/filters/poi_filter_taxonomy_term.dart';
import 'package:belluga_now/domain/map/filters/poi_filter_taxonomy_terms.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_type_value.dart';

class PoiFilterTaxonomyGroup {
  PoiFilterTaxonomyGroup({
    required this.typeValue,
    required this.labelValue,
    required PoiFilterTaxonomyTerms terms,
  }) : terms = List<PoiFilterTaxonomyTerm>.unmodifiable(terms.value);

  final PoiFilterTaxonomyTypeValue typeValue;
  final PoiFilterLabelValue labelValue;
  final List<PoiFilterTaxonomyTerm> terms;

  String get type => typeValue.value;
  String get label => labelValue.value;
}
