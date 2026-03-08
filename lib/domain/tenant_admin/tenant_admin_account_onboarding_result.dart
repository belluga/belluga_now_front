import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';

class TenantAdminAccountOnboardingResult {
  const TenantAdminAccountOnboardingResult({
    required this.account,
    required this.accountProfile,
  });

  final TenantAdminAccount account;
  final TenantAdminAccountProfile accountProfile;
}
