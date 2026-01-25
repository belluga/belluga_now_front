import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin_store.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TenantAdminAccountProfilesListScreen extends StatelessWidget {
  const TenantAdminAccountProfilesListScreen({
    super.key,
    required this.accountSlug,
  });

  final String accountSlug;

  @override
  Widget build(BuildContext context) {
    final store = GetIt.I.get<TenantAdminStore>();

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final profiles = store.profilesForAccount(accountSlug);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.router.maybePop(),
                  tooltip: 'Voltar',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Perfis - $accountSlug',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    context.router.push(
                      TenantAdminAccountProfileCreateRoute(accountSlug: accountSlug),
                    );
                  },
                  child: const Text('Criar'),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: profiles.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: profiles.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final profile = profiles[index];
                          return ListTile(
                            title: Text(profile.id),
                            subtitle: Text(profile.type),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              context.router.push(
                                TenantAdminAccountProfileDetailRoute(
                                  accountProfileId: profile.id,
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Nenhum perfil para esta conta ainda.'),
    );
  }
}
