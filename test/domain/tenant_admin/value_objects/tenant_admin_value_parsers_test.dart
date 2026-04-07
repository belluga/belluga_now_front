import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tenant admin text parsers reject structured values', () {
    expect(
      () => tenantAdminRequiredText({'title': 'bad'}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Invalid text value'),
        ),
      ),
    );

    expect(
      () => tenantAdminOptionalText(['bad']),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Invalid text value'),
        ),
      ),
    );
  });
}
