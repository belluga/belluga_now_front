import 'package:belluga_now/domain/tenant_admin/ownership_state.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_accounts_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tenantAdminAccountMatchesOwnershipSegment', () {
    test('does not map user_owned to unmanaged segment', () {
      final result = tenantAdminAccountMatchesOwnershipSegment(
        selectedOwnership: TenantAdminOwnershipState.unmanaged,
        accountOwnership: TenantAdminOwnershipState.userOwned,
      );

      expect(result, isFalse);
    });

    test('keeps tenant_owned strict match', () {
      final result = tenantAdminAccountMatchesOwnershipSegment(
        selectedOwnership: TenantAdminOwnershipState.tenantOwned,
        accountOwnership: TenantAdminOwnershipState.userOwned,
      );

      expect(result, isFalse);
    });
  });
}
