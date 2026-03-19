import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage(name: 'TenantAdminAccountProfileCreateRoute')
class TenantAdminAccountProfileCreateRoutePage extends StatelessWidget {
  const TenantAdminAccountProfileCreateRoutePage({
    super.key,
    @PathParam('accountSlug') required this.accountSlug,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
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
                TenantAdminAccountDetailRoute(accountSlug: accountSlug),
              ),
              child: const Text('Voltar para conta'),
            ),
          ],
        ),
      ),
    );
  }
}
