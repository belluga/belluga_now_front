import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_organization.dart';
import 'package:belluga_now/presentation/tenant_admin/organizations/screens/tenant_admin_organization_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminOrganizationDetailRoute')
class TenantAdminOrganizationDetailRoutePage
    extends ResolverRoute<TenantAdminOrganization, TenantAdminModule> {
  const TenantAdminOrganizationDetailRoutePage({
    super.key,
    @PathParam('organizationId') required this.organizationId,
  });

  final String organizationId;

  @override
  RouteResolverParams get resolverParams => {'organizationId': organizationId};

  @override
  Widget buildScreen(BuildContext context, TenantAdminOrganization model) =>
      TenantAdminOrganizationDetailScreen(organization: model);
}
