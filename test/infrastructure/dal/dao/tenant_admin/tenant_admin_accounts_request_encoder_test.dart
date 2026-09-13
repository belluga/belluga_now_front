import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_admin/tenant_admin_accounts_request_encoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes onboarding with bio and without retired content', () {
    const encoder = TenantAdminAccountsRequestEncoder();

    final payload = encoder.encodeCreateOnboarding(
      name: 'Account',
      ownershipState: TenantAdminOwnershipState.tenantOwned,
      profileType: 'artist',
      bio: '<p>Canonical bio</p>',
    );

    expect(payload['bio'], '<p>Canonical bio</p>');
    expect(payload, isNot(contains('content')));
  });

  test('encodes parent account publication status on update payload', () {
    const encoder = TenantAdminAccountsRequestEncoder();

    final payload = encoder.encodeUpdateAccount(publicationStatus: 'published');

    expect(payload['publication'], <String, dynamic>{'status': 'published'});
  });
}
