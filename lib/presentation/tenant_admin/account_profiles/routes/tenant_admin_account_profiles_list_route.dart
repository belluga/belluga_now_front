import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profiles_list_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminAccountProfilesListRoute')
class TenantAdminAccountProfilesListRoutePage extends StatelessWidget {
  const TenantAdminAccountProfilesListRoutePage({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    return TenantAdminAccountProfilesListScreen(accountSlug: accountSlug);
  }
}
