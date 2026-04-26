import 'package:belluga_now/infrastructure/dal/dto/map/map_filter_taxonomy_term_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves canonical taxonomy display snapshot fields', () {
    final dto = MapFilterTaxonomyTermDTO.fromJson({
      'type': 'genre',
      'value': 'samba',
      'name': 'Samba',
      'taxonomy_name': 'Genero musical',
      'label': 'Legacy Samba',
      'count': 7,
    });

    expect(dto.type, 'genre');
    expect(dto.value, 'samba');
    expect(dto.name, 'Samba');
    expect(dto.taxonomyName, 'Genero musical');
    expect(dto.label, 'Samba');
    expect(dto.displayLabel, 'Samba');
    expect(dto.count, 7);
  });

  test('falls back from name to compatibility label and then value', () {
    final compatibilityTerm = MapFilterTaxonomyTermDTO.fromJson({
      'type': 'genre',
      'value': 'samba',
      'label': 'Samba legado',
      'count': 1,
    });
    final legacyTerm = MapFilterTaxonomyTermDTO.fromJson({
      'type': 'genre',
      'value': 'samba',
      'count': 1,
    });

    expect(compatibilityTerm.displayLabel, 'Samba legado');
    expect(legacyTerm.displayLabel, 'samba');
  });
}
