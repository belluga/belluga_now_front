import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminAccountDetailRoute')
class TenantAdminAccountDetailRoutePage extends StatelessWidget {
  const TenantAdminAccountDetailRoutePage({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    return TenantAdminAccountDetailScreen(accountSlug: accountSlug);
  }
}
