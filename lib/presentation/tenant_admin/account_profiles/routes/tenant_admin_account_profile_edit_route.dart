import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminAccountProfileEditRoute')
class TenantAdminAccountProfileEditRoutePage extends StatelessWidget {
  const TenantAdminAccountProfileEditRoutePage({
    super.key,
    @PathParam('accountSlug') required this.accountSlug,
    @PathParam('accountProfileId') required this.accountProfileId,
  });

  final String accountSlug;
  final String accountProfileId;

  @override
  Widget build(BuildContext context) {
    return TenantAdminAccountProfileEditScreen(
      key: ValueKey(
        'tenant-admin-account-profile-edit-$accountSlug-$accountProfileId',
      ),
      accountSlug: accountSlug,
      accountProfileId: accountProfileId,
    );
  }
}
