import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/screens/tenant_admin_organizations_list_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminOrganizationsListRoute')
class TenantAdminOrganizationsListRoutePage extends StatelessWidget {
  const TenantAdminOrganizationsListRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminOrganizationsListScreen();
  }
}
