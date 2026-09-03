import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_account_profile_external_link_route_model.dart';
import 'package:belluga_now/application/router/resolvers/tenant_admin_account_profile_external_links_capability_disabled_route_exception.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/presentation/tenant_admin/account_profiles/screens/tenant_admin_account_profile_external_link_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminAccountProfileExternalLinkAddRoute')
class TenantAdminAccountProfileExternalLinkAddRoutePage
    extends
        ResolverRoute<
          TenantAdminAccountProfileExternalLinkRouteModel,
          TenantAdminModule
        > {
  const TenantAdminAccountProfileExternalLinkAddRoutePage({
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
  Future<TenantAdminAccountProfileExternalLinkRouteModel> resolve(
    BuildContext context,
    RouteResolverParams params,
  ) async {
    try {
      return await super.resolve(context, params);
    } on TenantAdminAccountProfileExternalLinksCapabilityDisabledRouteException {
      if (context.mounted) {
        await context.router.replace(
          TenantAdminAccountProfileEditRoute(
            accountSlug: accountSlug,
            accountProfileId: accountProfileId,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  ResolverErrorBuilder get errorBuilder => (context, error, retry) {
    if (error
        is TenantAdminAccountProfileExternalLinksCapabilityDisabledRouteException) {
      return const SizedBox.shrink();
    }
    return super.errorBuilder(context, error, retry);
  };

  @override
  Widget buildScreen(
    BuildContext context,
    TenantAdminAccountProfileExternalLinkRouteModel model,
  ) => TenantAdminAccountProfileExternalLinkFormScreen(
    accountSlug: accountSlug,
    accountProfile: model.profile,
    draft: model.draft,
  );
}
