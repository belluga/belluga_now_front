import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_term_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_type_value.dart';

class PoiFilterTaxonomyTerm {
  PoiFilterTaxonomyTerm({
    required this.typeValue,
    required this.valueValue,
    required this.labelValue,
    required this.countValue,
  });

  final PoiFilterTaxonomyTypeValue typeValue;
  final PoiFilterTaxonomyTermValue valueValue;
  final PoiFilterLabelValue labelValue;
  final PoiFilterCountValue countValue;

  String get type => typeValue.value;
  String get value => valueValue.value;
  String get label => labelValue.value;
  int get count => countValue.value;

  String get token =>
      '${type.trim().toLowerCase()}:${value.trim().toLowerCase()}';
}
