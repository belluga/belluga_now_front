import 'package:belluga_now/domain/map/filters/poi_filter_taxonomy_term.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_label_value.dart';
import 'package:belluga_now/domain/map/value_objects/poi_filter_taxonomy_type_value.dart';

class PoiFilterTaxonomyGroup {
  PoiFilterTaxonomyGroup({
    required String type,
    required String label,
    required this.terms,
  })  : typeValue = _buildTypeValue(type),
        labelValue = _buildLabelValue(label);

  final PoiFilterTaxonomyTypeValue typeValue;
  final PoiFilterLabelValue labelValue;
  final List<PoiFilterTaxonomyTerm> terms;

  String get type => typeValue.value;
  String get label => labelValue.value;

  static PoiFilterTaxonomyTypeValue _buildTypeValue(String raw) {
    final value = PoiFilterTaxonomyTypeValue()..parse(raw.trim().toLowerCase());
    return value;
  }

  static PoiFilterLabelValue _buildLabelValue(String raw) {
    final value = PoiFilterLabelValue()..parse(raw.trim());
    return value;
  }
}
