import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/screens/tenant_admin_organization_create_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminOrganizationCreateRoute')
class TenantAdminOrganizationCreateRoutePage extends StatelessWidget {
  const TenantAdminOrganizationCreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TenantAdminOrganizationCreateScreen();
  }
}
