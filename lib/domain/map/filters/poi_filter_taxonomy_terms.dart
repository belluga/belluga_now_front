import 'package:belluga_now/domain/map/filters/poi_filter_taxonomy_term.dart';

class PoiFilterTaxonomyTerms {
  PoiFilterTaxonomyTerms() : _value = <PoiFilterTaxonomyTerm>[];

  final List<PoiFilterTaxonomyTerm> _value;

  List<PoiFilterTaxonomyTerm> get value =>
      List<PoiFilterTaxonomyTerm>.unmodifiable(_value);

  void add(PoiFilterTaxonomyTerm term) {
    _value.add(term);
  }
}
