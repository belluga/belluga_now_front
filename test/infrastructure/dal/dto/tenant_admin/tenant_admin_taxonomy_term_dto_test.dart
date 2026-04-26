import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_taxonomy_term_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves canonical taxonomy display snapshot fields', () {
    final term = TenantAdminTaxonomyTermDTO.fromJson({
      'type': 'genre',
      'value': 'samba',
      'name': 'Samba',
      'taxonomy_name': 'Genero musical',
      'label': 'Legacy Samba',
    }).toDomain();

    expect(term.type, 'genre');
    expect(term.value, 'samba');
    expect(term.name, 'Samba');
    expect(term.taxonomyName, 'Genero musical');
    expect(term.label, 'Legacy Samba');
    expect(term.displayLabel, 'Samba');
  });

  test('falls back from name to compatibility label and then value', () {
    final compatibilityTerm = TenantAdminTaxonomyTermDTO.fromJson({
      'type': 'genre',
      'value': 'samba',
      'label': 'Samba legado',
    }).toDomain();
    final legacyTerm = TenantAdminTaxonomyTermDTO.fromJson({
      'type': 'genre',
      'value': 'samba',
    }).toDomain();

    expect(compatibilityTerm.displayLabel, 'Samba legado');
    expect(legacyTerm.displayLabel, 'samba');
  });
}
