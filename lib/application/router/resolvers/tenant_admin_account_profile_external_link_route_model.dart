import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/controllers/tenant_admin_account_profile_external_link_draft.dart';

final class TenantAdminAccountProfileExternalLinkRouteModel {
  const TenantAdminAccountProfileExternalLinkRouteModel({
    required this.profile,
    required this.draft,
  });

  final TenantAdminAccountProfile profile;
  final TenantAdminAccountProfileExternalLinkDraft draft;
}
