import 'package:belluga_now/presentation/tenant_admin/shared/utils/tenant_admin_form_value_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tenantAdminParseLatitude', () {
    test('parses decimal with dot', () {
      expect(tenantAdminParseLatitude('-20.6736'), -20.6736);
    });

    test('parses decimal with comma', () {
      expect(tenantAdminParseLatitude('-20,6736'), -20.6736);
    });

    test('returns null when value is out of range', () {
      expect(tenantAdminParseLatitude('95'), isNull);
    });
  });

  group('tenantAdminParseLongitude', () {
    test('parses negative longitude', () {
      expect(tenantAdminParseLongitude('-40.4976'), -40.4976);
    });

    test('returns null when value is out of range', () {
      expect(tenantAdminParseLongitude('181'), isNull);
    });
  });
}
