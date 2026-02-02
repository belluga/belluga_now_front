import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_create_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminAccountCreateRoute')
class TenantAdminAccountCreateRoutePage extends StatelessWidget {
  const TenantAdminAccountCreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminAccountCreateScreen();
  }
}
