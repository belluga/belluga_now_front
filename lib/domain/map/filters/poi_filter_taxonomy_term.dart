import 'package:belluga_now/domain/map/value_objects/poi_filter_count_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_term_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_type_value.dart';

class PoiFilterTaxonomyTerm {
  PoiFilterTaxonomyTerm({
    required String type,
    required String value,
    required String label,
    required int count,
  })  : typeValue = _buildTypeValue(type),
        valueValue = _buildValueValue(value),
        labelValue = _buildLabelValue(label),
        countValue = _buildCountValue(count);

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

  static PoiFilterTaxonomyTypeValue _buildTypeValue(String raw) {
    final value = PoiFilterTaxonomyTypeValue()..parse(raw.trim().toLowerCase());
    return value;
  }

  static PoiFilterTaxonomyTermValue _buildValueValue(String raw) {
    final value = PoiFilterTaxonomyTermValue()
      ..parse(raw.trim().toLowerCase());
    return value;
  }

  static PoiFilterLabelValue _buildLabelValue(String raw) {
    final value = PoiFilterLabelValue()..parse(raw.trim());
    return value;
  }

  static PoiFilterCountValue _buildCountValue(int raw) {
    final value = PoiFilterCountValue()..parse(raw.toString());
    return value;
  }
}
