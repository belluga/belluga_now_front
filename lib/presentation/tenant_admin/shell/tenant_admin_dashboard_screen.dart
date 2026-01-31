import 'package:auto_route/auto_route.dart';
import 'package:belluga_now/application/router/app_router.gr.dart';
import 'package:flutter/material.dart';

class TenantAdminDashboardScreen extends StatelessWidget {
  const TenantAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Visão geral',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _DashboardCard(
          icon: Icons.account_box_outlined,
          title: 'Contas',
          description: 'Gerencie contas e o perfil associado.',
          onTap: () {
            context.router.push(const TenantAdminAccountsListRoute());
          },
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: Icons.apartment_outlined,
          title: 'Organizações',
          description: 'Controle organizações do tenant.',
          onTap: () {
            context.router.push(const TenantAdminOrganizationsListRoute());
          },
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          icon: Icons.category_outlined,
          title: 'Tipos de Perfil',
          description: 'Defina tipos e capacidades.',
          onTap: () {
            context.router.push(const TenantAdminProfileTypesListRoute());
          },
        ),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Eventos'),
            subtitle: Text('Em breve'),
            enabled: false,
          ),
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
