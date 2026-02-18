import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_create_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminAccountProfileCreateRoute')
class TenantAdminAccountProfileCreateRoutePage extends StatelessWidget {
  const TenantAdminAccountProfileCreateRoutePage({
    super.key,
    @PathParam('accountSlug') required this.accountSlug,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    return TenantAdminAccountProfileCreateScreen(
      accountSlug: accountSlug,
    );
  }
}
