import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/screens/tenant_admin_organization_detail_screen.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminOrganizationDetailRoute')
class TenantAdminOrganizationDetailRoutePage extends StatelessWidget {
  const TenantAdminOrganizationDetailRoutePage({
    super.key,
    required this.organizationId,
  });

  final String organizationId;

  @override
  Widget build(BuildContext context) {
    return TenantAdminOrganizationDetailScreen(
      organizationId: organizationId,
    );
  }
}
