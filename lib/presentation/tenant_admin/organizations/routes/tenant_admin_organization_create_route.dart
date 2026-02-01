import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/controllers/tenant_admin_organizations_controller.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/screens/tenant_admin_organization_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

@RoutePage(name: 'TenantAdminOrganizationCreateRoute')
class TenantAdminOrganizationCreateRoutePage extends StatelessWidget {
  const TenantAdminOrganizationCreateRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TenantAdminOrganizationCreateScreen(
      controller: GetIt.I.get<TenantAdminOrganizationsController>(),
    );
  }
}
