import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_accounts_request_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes parent account publication status on update payload', () {
    const encoder = TenantAdminAccountsRequestEncoder();

    final payload = encoder.encodeUpdateAccount(publicationStatus: 'published');

    expect(payload['publication'], <String, dynamic>{'status': 'published'});
  });
}
