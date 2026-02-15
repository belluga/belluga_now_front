import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_slug_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tenantAdminSlugify', () {
    test('normalizes spaces and punctuation', () {
      expect(
        tenantAdminSlugify('  Tipo de Perfil! @2026  '),
        'tipo-de-perfil-2026',
      );
    });

    test('removes accents before slug generation', () {
      expect(
        tenantAdminSlugify('Música São João'),
        'musica-sao-joao',
      );
    });

    test('keeps manual separators without duplication', () {
      expect(
        tenantAdminSlugify('static___asset---type'),
        'static-asset-type',
      );
    });
  });
}
