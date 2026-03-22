import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/account_workspace_module.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:belluga_now/presentation/account_workspace/screens/account_workspace_create_event_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'AccountWorkspaceCreateEventRoute')
class AccountWorkspaceCreateEventRoutePage
    extends ResolverRoute<TenantAdminAccount, AccountWorkspaceModule> {
  const AccountWorkspaceCreateEventRoutePage({
    @PathParam('accountSlug') required this.accountSlug,
    super.key,
  });

  final String accountSlug;

  @override
  RouteResolverParams get resolverParams => {'accountSlug': accountSlug};

  @override
  Widget buildScreen(BuildContext context, TenantAdminAccount model) =>
      ModuleScope<AccountWorkspaceModule>(
        child: AccountWorkspaceCreateEventScreen(accountSlug: model.slug),
      );
}
