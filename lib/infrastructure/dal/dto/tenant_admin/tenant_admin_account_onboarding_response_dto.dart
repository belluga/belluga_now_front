import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/tenant_admin/tenant_admin_account_profile_dto.dart';

class TenantAdminAccountOnboardingResponseDTO {
  const TenantAdminAccountOnboardingResponseDTO({
    required this.account,
    required this.accountProfile,
  });

  final TenantAdminAccountDTO account;
  final TenantAdminAccountProfileDTO accountProfile;
}
