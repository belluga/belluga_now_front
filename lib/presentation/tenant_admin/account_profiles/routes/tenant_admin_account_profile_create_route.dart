import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/application/router/modular_app/modules/tenant_admin_module.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_account.dart';
import 'package:flutter/material.dart';
import 'package:get_it_modular_with_auto_route/get_it_modular_with_auto_route.dart';

@RoutePage(name: 'TenantAdminAccountProfileCreateRoute')
class TenantAdminAccountProfileCreateRoutePage
    extends ResolverRoute<TenantAdminAccount, TenantAdminModule> {
  const TenantAdminAccountProfileCreateRoutePage({
    super.key,
    @PathParam('accountSlug') required this.accountSlug,
  });

  final String accountSlug;

  @override
  RouteResolverParams get resolverParams => {'accountSlug': accountSlug};

  @override
  Widget buildScreen(BuildContext context, TenantAdminAccount model) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluxo indisponível'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Criação standalone de perfil foi descontinuada.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Use o onboarding de conta para criar conta+perfil em um único fluxo.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.router.replace(
                TenantAdminAccountDetailRoute(accountSlug: model.slug),
              ),
              child: const Text('Voltar para conta'),
            ),
          ],
        ),
      ),
    );
  }
}
