import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account_profile.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminAccountProfileEditRoute')
class TenantAdminAccountProfileEditRoutePage
    extends ResolverRoute<TenantAdminAccountProfile, TenantAdminModule> {
  const TenantAdminAccountProfileEditRoutePage({
    super.key,
    @PathParam('accountSlug') required this.accountSlug,
    @PathParam('accountProfileId') required this.accountProfileId,
  });

  final String accountSlug;
  final String accountProfileId;

  @override
  RouteResolverParams get resolverParams => {
        'accountSlug': accountSlug,
        'accountProfileId': accountProfileId,
      };

  @override
  Widget buildScreen(BuildContext context, TenantAdminAccountProfile model) {
    return TenantAdminAccountProfileEditScreen(
      key: ValueKey(
        'tenant-admin-account-profile-edit-$accountSlug-${model.id}',
      ),
      accountSlug: accountSlug,
      accountProfileId: model.id,
    );
  }
}
