import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/presentation/tenant_admin/accounts/screens/tenant_admin_account_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminAccountDetailRoute')
class TenantAdminAccountDetailRoutePage
    extends ResolverRoute<TenantAdminAccount, TenantAdminModule> {
  const TenantAdminAccountDetailRoutePage({
    super.key,
    @PathParam('accountSlug') required this.accountSlug,
  });

  final String accountSlug;

  @override
  RouteResolverParams get resolverParams => {'accountSlug': accountSlug};

  @override
  Widget buildScreen(BuildContext context, TenantAdminAccount model) {
    return TenantAdminAccountDetailScreen(
      accountSlug: model.slug,
    );
  }
}
